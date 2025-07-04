import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/group.dart';
import '../models/sos_message.dart';
import '../models/resource_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import 'dart:convert';

class LocalStorage {
  static const String _userProfileBox = 'user_profile';
  static const String _groupsBox = 'groups';
  static const String _sosLogBox = 'sos_log';
  static const String _resourcesBox = 'resources';
  static const String _settingsBox = 'settings';
  static const String _contactsKey = 'emergency_contacts';

  static Future<void> initialize() async {
    try {
    await Hive.initFlutter();
    
      // Register adapters with error handling
      if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(GroupAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(GroupMemberAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(SosMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ResourceModelAdapter());
      }
    
      // Open boxes with error handling
      try {
    await Hive.openBox<UserProfile>(_userProfileBox);
      } catch (e) {
        print('Error opening user profile box: $e');
      }
      
      try {
    await Hive.openBox<Group>(_groupsBox);
      } catch (e) {
        print('Error opening groups box: $e');
      }
      
      try {
    await Hive.openBox<SosMessage>(_sosLogBox);
      } catch (e) {
        print('Error opening SOS log box: $e');
      }
      
      try {
    await Hive.openBox<ResourceModel>(_resourcesBox);
      } catch (e) {
        print('Error opening resources box: $e');
      }
      
      try {
    await Hive.openBox(_settingsBox);
      } catch (e) {
        print('Error opening settings box: $e');
      }
      
    } catch (e) {
      print('Error initializing Hive: $e');
      // Continue without Hive if it fails
    }
  }

  // User Profile Methods
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
    final box = Hive.box<UserProfile>(_userProfileBox);
    await box.put('current', profile);
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  static UserProfile? getUserProfile() {
    try {
    final box = Hive.box<UserProfile>(_userProfileBox);
    return box.get('current');
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Group Methods
  static Future<void> saveGroup(Group group) async {
    try {
    final box = Hive.box<Group>(_groupsBox);
    await box.put(group.id, group);
    } catch (e) {
      print('Error saving group: $e');
    }
  }

  static Group? getGroup(String groupId) {
    try {
    final box = Hive.box<Group>(_groupsBox);
    return box.get(groupId);
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  static List<Group> getAllGroups() {
    try {
    final box = Hive.box<Group>(_groupsBox);
      if (!box.isOpen) {
        print('ERROR: Groups box is not open!');
        return [];
      }
      final groups = box.values.toList();
      print('LocalStorage.getAllGroups() called, box is open, found ${groups.length} groups');
      for (var group in groups) {
        print('  - ${group.name} (${group.id}) with ${group.members.length} members');
      }
      return groups;
    } catch (e) {
      print('Error getting all groups: $e');
      return [];
    }
  }

  static Future<void> deleteGroup(String groupId) async {
    try {
    final box = Hive.box<Group>(_groupsBox);
    await box.delete(groupId);
    } catch (e) {
      print('Error deleting group: $e');
    }
  }

  // SOS Log Methods
  static Future<void> addSosToLog(SosMessage sos) async {
    final box = Hive.box<SosMessage>(_sosLogBox);
    await box.add(sos);
  }

  static List<SosMessage> getSosLog() {
    final box = Hive.box<SosMessage>(_sosLogBox);
    return box.values.toList();
  }

  static Future<void> clearSosLog() async {
    final box = Hive.box<SosMessage>(_sosLogBox);
    await box.clear();
  }

  // Resource Methods
  static Future<void> saveResource(ResourceModel resource) async {
    final box = Hive.box<ResourceModel>(_resourcesBox);
    await box.put(resource.id, resource);
  }

  static List<ResourceModel> getAllResources() {
    final box = Hive.box<ResourceModel>(_resourcesBox);
    return box.values.toList();
  }

  static Future<void> deleteResource(String resourceId) async {
    final box = Hive.box<ResourceModel>(_resourcesBox);
    await box.delete(resourceId);
  }

  // Settings Methods
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> deleteSetting(String key) async {
    final box = Hive.box(_settingsBox);
    await box.delete(key);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await Hive.box<UserProfile>(_userProfileBox).clear();
    await Hive.box<Group>(_groupsBox).clear();
    await Hive.box<SosMessage>(_sosLogBox).clear();
    await Hive.box<ResourceModel>(_resourcesBox).clear();
    await Hive.box(_settingsBox).clear();
  }

  static Future<List<Contact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_contactsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Contact.fromJson(e)).toList();
  }

  static Future<void> saveContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(contacts.map((e) => e.toJson()).toList());
    await prefs.setString(_contactsKey, jsonString);
  }

  static Future<void> addContact(Contact contact) async {
    final contacts = await getContacts();
    contacts.add(contact);
    await saveContacts(contacts);
  }

  static Future<void> updateContact(int index, Contact contact) async {
    final contacts = await getContacts();
    if (index >= 0 && index < contacts.length) {
      contacts[index] = contact;
      await saveContacts(contacts);
    }
  }

  static Future<void> deleteContact(int index) async {
    final contacts = await getContacts();
    if (index >= 0 && index < contacts.length) {
      contacts.removeAt(index);
      await saveContacts(contacts);
    }
  }
}

// Hive Adapters
class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile.fromJson(Map<String, dynamic>.from(reader.read()));
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.write(obj.toJson());
  }
}

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 1;

  @override
  Group read(BinaryReader reader) {
    return Group.fromJson(Map<String, dynamic>.from(reader.read()));
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer.write(obj.toJson());
  }
}

class GroupMemberAdapter extends TypeAdapter<GroupMember> {
  @override
  final int typeId = 2;

  @override
  GroupMember read(BinaryReader reader) {
    return GroupMember.fromJson(Map<String, dynamic>.from(reader.read()));
  }

  @override
  void write(BinaryWriter writer, GroupMember obj) {
    writer.write(obj.toJson());
  }
}

class SosMessageAdapter extends TypeAdapter<SosMessage> {
  @override
  final int typeId = 3;

  @override
  SosMessage read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.read());
    return SosMessage(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts']),
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      message: map['msg'],
      ttl: map['ttl'],
    );
  }

  @override
  void write(BinaryWriter writer, SosMessage obj) {
    writer.write({
      'id': obj.id,
      'ts': obj.timestamp.millisecondsSinceEpoch,
      'lat': obj.latitude,
      'lng': obj.longitude,
      'msg': obj.message,
      'ttl': obj.ttl,
    });
  }
}

class ResourceModelAdapter extends TypeAdapter<ResourceModel> {
  @override
  final int typeId = 4;

  @override
  ResourceModel read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.read());
    return ResourceModel(
      id: map['id'],
      title: map['title'],
      description: map['desc'],
      type: ResourceType.values[map['type']],
      category: ResourceCategory.values[map['cat']],
      userId: map['uid'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts']),
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      ttl: map['ttl'],
      isUrgent: map['urgent'] ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ResourceModel obj) {
    writer.write({
      'id': obj.id,
      'title': obj.title,
      'desc': obj.description,
      'type': obj.type.index,
      'cat': obj.category.index,
      'uid': obj.userId,
      'ts': obj.timestamp.millisecondsSinceEpoch,
      'lat': obj.latitude,
      'lng': obj.longitude,
      'ttl': obj.ttl,
      'urgent': obj.isUrgent,
    });
  }
} 