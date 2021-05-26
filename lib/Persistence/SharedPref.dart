import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// ==== DATA ====

// Load
Future<int> loadCurrentCupSize() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('size') ?? 300;
}

Future<int> loadCurrentCupCounter() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('counter') ?? 0;
}

// Save
Future<void> saveCurrentCupCounter(int newCounter) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('counter', newCounter);
}

Future<void> saveSize(int size) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('size', size);
}

// ==== SETTINGS ====

// Load
Future<bool> loadShakeSettings() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('shake') ?? false;
}

Future<bool> loadPowerSettings() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('power') ?? false;
}

Future<int> loadWeight() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('weight') ?? 40;
}

Future<String> loadGender() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('gender') ?? 'choose';
}

Future<String> loadLanguage(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('language') ?? context.locale;
}

// Save
Future<void> savePower(bool isPowerBtnAddEnabled) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('power', isPowerBtnAddEnabled);
}

Future<void> saveShaking(bool isShakingAddEnabled) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('shake', isShakingAddEnabled);
}

Future<void> saveWeight(int newWeight) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('weight', newWeight);
}

Future<void> saveGender(String gender) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('gender', gender);
}

Future<void> saveLanguage(String lang) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', lang);
}
