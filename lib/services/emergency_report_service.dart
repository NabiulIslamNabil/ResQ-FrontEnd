import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EmergencyReportService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  // Helper method to construct API URLs
  static String _buildUrl(String endpoint) {
    return '$_baseUrl/${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}';
  }

  // Submit victim emergency report
  static Future<bool> submitVictimReport({
    required BuildContext context,
    required String incidentType,
    required Map<String, dynamic> details,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        return false;
      }

      // Ensure description is not blank by generating one from answers if needed
      String description = details['description'] ?? '';
      if (description.isEmpty && details['answers'] is Map) {
        // Generate description from answers
        final Map<String, dynamic> answers = details['answers'];
        description = answers.entries
            .map((entry) => "${entry.key}: ${entry.value}")
            .join("\n");
      }

      // Still ensure we have some description
      if (description.isEmpty) {
        description =
            'Emergency $incidentType report submitted from ResQ mobile app';
      }

      // Format the request according to API requirements
      final Map<String, dynamic> requestBody = {
        'reporter_type': details['reporter_type'] ?? 'VICTIM',
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'is_emergency': true,
        'tag_ids': details['tag_ids'] ?? [],
        'incident_type': incidentType,
        'contact_info': details['contact_info'] ?? '',
      };

      // Print request for debugging
      debugPrint('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(_buildUrl('emergency/reports/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      // Print response for debugging
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error submitting victim report: $e');
      return false;
    }
  }

  // Submit spectator incident report
  static Future<bool> submitIncidentReport({
    required BuildContext context,
    required String incidentType,
    required Map<String, dynamic> details,
    required double latitude,
    required double longitude,
    String? address,
    List<String>? mediaUrls,
    String? contactInfo,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        return false;
      }

      // Ensure description is not blank
      String description = details['description'] ?? '';
      if (description.isEmpty && details['answers'] is Map) {
        // Generate description from answers
        final Map<String, dynamic> answers = details['answers'];
        description = answers.entries
            .map((entry) => "${entry.key}: ${entry.value}")
            .join("\n");
      }

      if (description.isEmpty) {
        description =
            'Spectator report for $incidentType submitted from ResQ mobile app';
      }

      // Format the request according to updated API documentation
      final Map<String, dynamic> requestBody = {
        'reporter_type': details['reporter_type'] ?? 'SPECTATOR',
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'is_emergency': true,
        'incident_type': incidentType,
        'contact_info': contactInfo ?? details['contact_info'] ?? '',
      };

      // Add severity if available
      if (details['severity'] != null) {
        requestBody['severity'] = details['severity'];
      }

      // Add people_count if available
      if (details['people_involved'] != null) {
        requestBody['people_count'] = details['people_involved'];
      }

      // Only add tag_ids if not null and not empty
      if (details['tag_ids'] != null && details['tag_ids'].isNotEmpty) {
        requestBody['tag_ids'] = details['tag_ids'];
      }

      // Only add media_urls if not null and not empty
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        requestBody['media_urls'] = mediaUrls;
      }

      // Print request for debugging
      debugPrint('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(_buildUrl('emergency/reports/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      // Print response for debugging
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error submitting incident report: $e');
      return false;
    }
  }

  // Submit emergency report (generic method that can be used for both victim and spectator reports)
  static Future<bool> submitEmergencyReport({
    required BuildContext context,
    required String incidentType,
    required Map<String, dynamic> details,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        return false;
      }

      // Extract fields that need to be at root level
      String description = details['description'] ?? '';
      String reporterType = details['reporter_type'] ?? 'SPECTATOR';
      bool isEmergency = details['is_emergency'] ?? true;

      // Prepare the report data with the correct structure
      final Map<String, dynamic> requestBody = {
        'incident_type': incidentType,
        'latitude': latitude,
        'longitude': longitude,
        'reporter_type': reporterType,
        'description': description,
        'is_emergency': isEmergency,
      };

      // Add address if provided
      if (address != null && address.isNotEmpty) {
        requestBody['address'] = address;
      }

      // Add any other fields from details that should be at the root level
      if (details['priority'] != null) {
        requestBody['priority'] = details['priority'];
      }

      if (details['contact_info'] != null) {
        requestBody['contact_info'] = details['contact_info'];
      }

      if (details['tag_ids'] != null) {
        requestBody['tag_ids'] = details['tag_ids'];
      }

      // For debugging
      debugPrint(
        'Request body for submitEmergencyReport: ${json.encode(requestBody)}',
      );

      final response = await http.post(
        Uri.parse(_buildUrl('emergency/reports/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error submitting emergency report: $e');
      return false;
    }
  }

  // Update emergency status
  static Future<bool> updateEmergencyStatus({
    required BuildContext context,
    required String emergencyId,
    required String status,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        return false;
      }

      // Correct API endpoint format: emergency/reports/{id}/
      final response = await http.patch(
        Uri.parse(_buildUrl('emergency/reports/$emergencyId/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      // Print response for debugging
      debugPrint('Status update response: ${response.statusCode}');
      debugPrint('Status update body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating emergency status: $e');
      return false;
    }
  }

  // Get all emergency reports
  static Future<List<dynamic>> getEmergencyReports(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse(_buildUrl('emergency/reports/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as List;
      } else {
        debugPrint('Failed to load reports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting emergency reports: $e');
      return [];
    }
  }
}
