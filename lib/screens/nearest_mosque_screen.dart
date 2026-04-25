// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/models/mosque_place.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'package:salat_pro/services/location_service.dart';
import 'package:salat_pro/services/mosque_service.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/utils/map_navigation.dart';

/// OpenStreetMap + Overpass: nearby Muslim places of worship (no Google Maps SDK).
class NearestMosqueScreen extends StatefulWidget {
  const NearestMosqueScreen({super.key, required this.isActiveTab});

  /// False when another bottom-nav tab is selected (widget may stay mounted under [Offstage]).
  final bool isActiveTab;

  @override
  State<NearestMosqueScreen> createState() => _NearestMosqueScreenState();
}

class _NearestMosqueScreenState extends State<NearestMosqueScreen> {
  final MapController _mapController = MapController();

  SettingsProvider? _settings;
  String? _trackedLocationSig;

  bool _loadingLocation = true;
  bool _loadingMosques = false;
  LocationAccessIssue _locationIssue = LocationAccessIssue.none;
  String? _mosqueFetchError;
  Position? _user;
  List<MosquePlace> _mosques = [];

  /// Ignores stale async completions when [isActiveTab] toggles or a newer load starts.
  int _loadGeneration = 0;

  static String _locationSig(SettingsProvider s) =>
      '${s.useManualLocation}:${s.manualLatitude}:${s.manualLongitude}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settings != null) return;
    final s = context.read<SettingsProvider>();
    _settings = s;
    _trackedLocationSig = _locationSig(s);
    s.addListener(_onSettingsLocationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAll();
    });
  }

  @override
  void didUpdateWidget(NearestMosqueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab) {
      _loadAll();
    }
  }

  void _onSettingsLocationChanged() {
    if (!mounted || !widget.isActiveTab || _settings == null) return;
    final sig = _locationSig(_settings!);
    if (sig == _trackedLocationSig) return;
    _trackedLocationSig = sig;
    _loadAll();
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsLocationChanged);
    _mapController.dispose();
    super.dispose();
  }

  Position _positionFromManual(SettingsProvider settings) {
    return Position(
      latitude: settings.manualLatitude,
      longitude: settings.manualLongitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  Future<void> _loadAll() async {
    final gen = ++_loadGeneration;
    final settings = _settings ?? context.read<SettingsProvider>();

    setState(() {
      _loadingLocation = true;
      _loadingMosques = false;
      _locationIssue = LocationAccessIssue.none;
      _mosqueFetchError = null;
      _mosques = [];
    });

    late final LocationResolveResult loc;
    if (settings.useManualLocation) {
      loc = LocationResolveResult(position: _positionFromManual(settings));
    } else {
      loc = await LocationService.resolveCurrentPositionForMap();
    }

    if (!mounted || gen != _loadGeneration) return;

    if (!loc.hasPosition) {
      setState(() {
        _loadingLocation = false;
        _locationIssue = loc.issue;
        _user = null;
      });
      _trackedLocationSig = _locationSig(settings);
      return;
    }

    setState(() {
      _user = loc.position;
      _loadingLocation = false;
      _loadingMosques = true;
    });
    _trackedLocationSig = _locationSig(settings);

    await _fetchMosquesForUser(gen);
  }

  Future<void> _fetchMosquesForUser(int gen) async {
    final u = _user;
    if (u == null) return;

    setState(() {
      _loadingMosques = true;
      _mosqueFetchError = null;
    });

    try {
      final list = await MosqueService.fetchNearbyMosques(
        userLat: u.latitude,
        userLon: u.longitude,
        radiusMeters: MosqueService.defaultRadiusMeters,
      );
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _mosques = list;
        _loadingMosques = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToData());
    } on MosqueServiceException catch (e) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _mosqueFetchError = e.message;
        _loadingMosques = false;
        _mosques = [];
      });
    } catch (e) {
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _mosqueFetchError = 'Could not load mosques. Check your connection and try again.';
        _loadingMosques = false;
        _mosques = [];
      });
    }
  }

  void _fitMapToData() {
    final u = _user;
    if (u == null) return;

    final points = <LatLng>[LatLng(u.latitude, u.longitude)];
    for (final m in _mosques) {
      points.add(LatLng(m.latitude, m.longitude));
    }

    try {
      if (points.length == 1) {
        _mapController.move(LatLng(u.latitude, u.longitude), 14);
      } else {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
            maxZoom: 16,
          ),
        );
      }
    } catch (_) {
      _mapController.move(LatLng(u.latitude, u.longitude), 13);
    }
  }

  Widget _buildMapStack(BuildContext context, Position u) {
    final palette = context.palette;
    final s = context.strings;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(u.latitude, u.longitude),
              initialZoom: 14,
              backgroundColor: palette.surface,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.salatpro.salat_pro',
                maxNativeZoom: 19,
              ),
              SimpleAttributionWidget(
                backgroundColor: palette.surface.withValues(alpha: 0.92),
                source: Text(
                  'OpenStreetMap',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () => unawaited(_openOsmCopyright()),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(u.latitude, u.longitude),
                    width: 44,
                    height: 44,
                    child: Tooltip(
                      message: s.yourLocationTooltip,
                      child: Icon(
                        Icons.my_location,
                        color: palette.primary,
                        size: 40,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  ..._mosques.map(
                    (m) => Marker(
                      point: LatLng(m.latitude, m.longitude),
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: m.displayName,
                        child: Icon(
                          Icons.mosque,
                          color: palette.secondary,
                          size: 36,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_loadingMosques)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: Card(
                    color: palette.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              s.loadingMosques,
                              style: TextStyle(color: palette.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadiusToolbar(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    final km = (MosqueService.defaultRadiusMeters / 1000).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Flexible(
            child: Text(
              s.withinKm(km),
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_mosqueFetchError != null) ...[
            TextButton.icon(
              onPressed: () {
                final g = ++_loadGeneration;
                _fetchMosquesForUser(g);
              },
              icon: Icon(Icons.refresh, size: 18, color: palette.error),
              label: Text(s.retry, style: TextStyle(color: palette.error)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openOsmCopyright() async {
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.background, palette.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.nearestMosqueTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: palette.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: s.refreshMapsTooltip,
            onPressed: _loadAll,
            icon: Icon(Icons.refresh, color: palette.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    if (_loadingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: palette.primary),
            const SizedBox(height: 16),
            Text(s.findingLocation, style: TextStyle(color: palette.textSecondary)),
          ],
        ),
      );
    }

    if (_locationIssue != LocationAccessIssue.none && _user == null) {
      return _buildLocationIssueState(context);
    }

    final u = _user!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            constraints.maxWidth >= 560 && constraints.maxWidth > constraints.maxHeight * 1.05;
        final mapHeight = (constraints.maxHeight * (constraints.maxHeight < 520 ? 0.34 : 0.40)).clamp(
          168.0,
          340.0,
        );

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 55,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
                  child: _buildMapStack(context, u),
                ),
              ),
              Expanded(
                flex: 45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRadiusToolbar(context),
                    Expanded(child: _buildListSection(context)),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: mapHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildMapStack(context, u),
              ),
            ),
            const SizedBox(height: 8),
            _buildRadiusToolbar(context),
            Expanded(child: _buildListSection(context)),
          ],
        );
      },
    );
  }

  Widget _buildLocationIssueState(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    String title;
    String body;
    switch (_locationIssue) {
      case LocationAccessIssue.denied:
        title = s.locationOffTitle;
        body = s.locationOffBody;
        break;
      case LocationAccessIssue.deniedForever:
        title = s.locationBlockedTitle;
        body = s.locationBlockedBody;
        break;
      case LocationAccessIssue.serviceDisabled:
        title = s.locationServiceOffTitle;
        body = s.locationServiceOffBody;
        break;
      case LocationAccessIssue.error:
        title = s.locationUnavailableTitle;
        body = s.locationUnavailableBody;
        break;
      case LocationAccessIssue.none:
        title = s.locationGeneric;
        body = '';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _locationIssue == LocationAccessIssue.serviceDisabled
                  ? Icons.location_disabled
                  : Icons.location_off_outlined,
              size: 64,
              color: palette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.textPrimary)),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh),
                  label: Text(s.retry),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                  ),
                ),
                if (_locationIssue == LocationAccessIssue.deniedForever)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(s.openSettings),
                    style: OutlinedButton.styleFrom(foregroundColor: palette.primary),
                  ),
                if (_locationIssue == LocationAccessIssue.serviceDisabled)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Geolocator.openLocationSettings();
                    },
                    icon: const Icon(Icons.gps_fixed),
                    label: Text(s.locationSettings),
                    style: OutlinedButton.styleFrom(foregroundColor: palette.primary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    if (_mosqueFetchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: palette.textSecondary),
              const SizedBox(height: 12),
              Text(
                _mosqueFetchError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingMosques && _mosques.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: palette.primary),
      );
    }

    if (_mosques.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.noMosquesFound,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, height: 1.4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _mosques.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = _mosques[i];
        return Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mosque, color: palette.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.formatDistanceMeters(m.distanceMeters),
                        style: TextStyle(fontSize: 13, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: s.openInMapsTooltip,
                  onPressed: () async {
                    final ok = await MapNavigationLauncher.openExternalNavigation(
                      latitude: m.latitude,
                      longitude: m.longitude,
                      label: m.displayName,
                    );
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.couldNotOpenMaps)),
                      );
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primary.withValues(alpha: 0.2),
                    foregroundColor: palette.primary,
                  ),
                  icon: const Icon(Icons.navigation_outlined),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
