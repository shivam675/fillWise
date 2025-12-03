import 'package:flutter/material.dart';

enum NavSection { chat, templates, documents, settings }

class NavigationProvider extends ChangeNotifier {
  NavSection _destination = NavSection.chat;

  NavSection get destination => _destination;

  void setDestination(NavSection destination) {
    if (_destination == destination) return;
    _destination = destination;
    notifyListeners();
  }
}
