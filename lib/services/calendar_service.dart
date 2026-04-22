/// CYKEL — Calendar Integration Service
/// Adds cycling events to device calendar with reminders

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import '../features/events/domain/event.dart';

class CalendarService {
  /// Add a cycling event to the device calendar
  /// Returns true if successfully added, false otherwise
  static Future<bool> addEventToCalendar(RideEvent event) async {
    try {
      final calendarEvent = Event(
        title: event.title,
        description: _buildEventDescription(event),
        location: '${event.meetingPoint.name ?? event.meetingPoint.address}, '
                  '${event.meetingPoint.latitude}, ${event.meetingPoint.longitude}',
        startDate: event.dateTime,
        // Duration defaults to event's estimated duration, or 2 hours
        endDate: event.dateTime.add(
          Duration(minutes: event.durationMinutes ?? 120),
        ),
        allDay: false,
        // iOS specific reminders
        iosParams: IOSParams(
          reminder: const Duration(hours: 1), // Remind 1 hour before
          url: 'cykel://event/${event.id}', // Deep link to event
        ),
        // Android specific reminders
        androidParams: const AndroidParams(
          emailInvites: null,
        ),
      );

      final result = await Add2Calendar.addEvent2Cal(calendarEvent);
      
      if (result) {
        debugPrint('[CalendarService] ✅ Added event "${event.title}" to calendar');
      } else {
        debugPrint('[CalendarService] ⚠️ User cancelled adding event to calendar');
      }
      
      return result;
    } catch (e) {
      debugPrint('[CalendarService] ❌ Failed to add event to calendar: $e');
      return false;
    }
  }

  /// Build a detailed event description with ride details
  static String _buildEventDescription(RideEvent event) {
    final buffer = StringBuffer();
    
    // Basic description
    if (event.description != null) {
      buffer.writeln(event.description);
      buffer.writeln();
    }
    
    // Event type and difficulty
    buffer.writeln('🚴 ${event.eventType.label} - ${event.difficulty.label}');
    buffer.writeln();
    
    // Ride details
    if (event.distanceKm != null) {
      buffer.writeln('📏 Distance: ${event.distanceKm}km');
    }
    
    if (event.durationMinutes != null) {
      final hours = event.durationMinutes! ~/ 60;
      final minutes = event.durationMinutes! % 60;
      if (hours > 0) {
        buffer.writeln('⏱️ Duration: ${hours}h ${minutes}min');
      } else {
        buffer.writeln('⏱️ Duration: ${minutes}min');
      }
    }
    
    if (event.paceKmh != null) {
      buffer.writeln('🚀 Pace: ${event.paceKmh}km/h');
    }
    
    buffer.writeln();
    
    // Meeting point details
    buffer.writeln('📍 Meeting Point:');
    if (event.meetingPoint.name != null) {
      buffer.writeln('   ${event.meetingPoint.name}');
    }
    buffer.writeln('   ${event.meetingPoint.address}');
    
    if (event.meetingPoint.instructions != null) {
      buffer.writeln();
      buffer.writeln('ℹ️ Instructions:');
      buffer.writeln('   ${event.meetingPoint.instructions}');
    }
    
    buffer.writeln();
    
    // Event settings
    if (event.isNoDrop) {
      buffer.writeln('✅ No-drop ride (group waits for everyone)');
    }
    
    if (event.requiresLights) {
      buffer.writeln('💡 Lights required');
    }
    
    // Participants
    if (event.maxParticipants != null) {
      buffer.writeln('👥 Max participants: ${event.maxParticipants}');
    }
    
    // Age restrictions
    if (event.hasAgeRestriction) {
      buffer.writeln('🔞 Age range: ${event.ageRangeText}');
    }
    
    buffer.writeln();
    buffer.writeln('Organized by: ${event.organizerName}');
    buffer.writeln();
    buffer.writeln('Added via CYKEL App');
    
    return buffer.toString();
  }

  /// Check if the app has calendar permission (platform specific)
  /// Note: add_2_calendar handles permissions internally
  static Future<bool> hasCalendarPermission() async {
    // The add_2_calendar plugin handles permissions automatically
    // when addEvent2Cal is called, so we always return true
    return true;
  }

  /// Request calendar permission (handled by add_2_calendar)
  static Future<bool> requestCalendarPermission() async {
    // Permission is requested automatically by add_2_calendar
    return true;
  }
}
