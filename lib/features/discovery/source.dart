import 'package:flutter/material.dart';

abstract class DiscoverySource {
  const DiscoverySource();

  String get id;
  String get name;
  IconData get icon;

  Future<List<DiscoveryItem>> search(String keyword);
  Future<DiscoveryDetail> loadDetail(DiscoveryItem item);
}

class DiscoveryItem {
  const DiscoveryItem({
    required this.source,
    required this.sourceItemId,
    required this.title,
    required this.detailUrl,
    this.author,
    this.imageUrl,
    this.description,
    this.durationSeconds,
    this.publishedAt,
  });

  final DiscoverySource source;
  final String sourceItemId;
  final String title;
  final String detailUrl;
  final String? author;
  final String? imageUrl;
  final String? description;
  final int? durationSeconds;
  final DateTime? publishedAt;
}

class DiscoveryDetail {
  const DiscoveryDetail({
    required this.title,
    required this.entries,
    this.author,
    this.imageUrl,
    this.description,
  });

  final String title;
  final String? author;
  final String? imageUrl;
  final String? description;
  final List<DiscoveryDetailEntry> entries;
}

class DiscoveryDetailEntry {
  const DiscoveryDetailEntry({
    required this.title,
    this.subtitle,
    this.description,
  });

  final String title;
  final String? subtitle;
  final String? description;
}
