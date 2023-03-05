import 'dart:async';

import 'package:flutter/material.dart';

class SearchManager {
  SearchManager();

  final names = <String>[
    'Simon',
    'Steve',
    'Randal',
    'Dalane',
    'Dalann',
    'Dalan',
    'Dala',
    'Dalanb',
    'Dalanq',
    'Dalans',
    'Dalanr',
  ];

  Future<List<String>> performSearch(String query) async {
    final results = <String>[];
    for (final name in names) {
      if (name.toLowerCase().contains(query.toLowerCase())) {
        results.add(name);
      }
    }
    return results;
  }
}

@immutable
class SearchApp extends StatefulWidget {
  const SearchApp({super.key});

  static SearchAppState of(BuildContext context) {
    return context.findAncestorStateOfType<SearchAppState>()!;
  }

  @override
  State<SearchApp> createState() => SearchAppState();
}

class SearchAppState extends State<SearchApp> {
  final searchManager = SearchManager();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

@immutable
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      // alignment: Alignment.center,
      scale: 0.8, // embiggen
      child: Material(
        child: Column(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
              child: SearchField(),
            ),
            ListTile(
              title: Text('Blah 1'),
            ),
            ListTile(
              title: Text('Blah 2'),
            ),
            ListTile(
              title: Text('Blah 3'),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _width = ValueNotifier<double>(0.0);
  final _layerLink = LayerLink();
  final _focusNode = FocusNode();
  final _controller = TextEditingController();

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusOrTextChanged);
    _controller.addListener(_onFocusOrTextChanged);
  }

  void _onFocusOrTextChanged() {
    final shouldShowOverlay =
        _focusNode.hasFocus && _controller.text.trim().isNotEmpty;
    if (_overlayEntry != null && !shouldShowOverlay) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    } else if (_overlayEntry == null && shouldShowOverlay) {
      _overlayEntry = OverlayEntry(
        builder: (BuildContext builderContext) {
          return SearchSuggestionsList(
            layerLink: _layerLink,
            controller: _controller,
            width: _width,
          );
        },
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusOrTextChanged);
    _focusNode.dispose();
    _controller.removeListener(_onFocusOrTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      scheduleMicrotask(() => _width.value = constraints.maxWidth);
      return CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          focusNode: _focusNode,
          controller: _controller,
        ),
      );
    });
  }
}

@immutable
class SearchSuggestionsList extends StatefulWidget {
  const SearchSuggestionsList({
    super.key,
    required this.layerLink,
    required this.controller,
    required this.width,
  });

  final LayerLink layerLink;
  final TextEditingController controller;
  final ValueNotifier<double> width;

  @override
  State<SearchSuggestionsList> createState() => _SearchSuggestionsListState();
}

class _SearchSuggestionsListState extends State<SearchSuggestionsList> {
  late SearchManager searchManager;
  late Future<List<String>> results;

  @override
  void initState() {
    super.initState();
    searchManager = SearchApp.of(context).searchManager;
    widget.controller.addListener(_onTextChanged);
    _onTextChanged();
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    setState(() {
      results = searchManager.performSearch(text);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: widget.layerLink,
      followerAnchor: Alignment.topLeft,
      targetAnchor: Alignment.bottomLeft,
      showWhenUnlinked: false,
      child: Align(
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder(
          valueListenable: widget.width,
          builder: (BuildContext context, double width, Widget? child) {
            return SizedBox(
              width: width,
              child: child,
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Material(
              type: MaterialType.card,
              elevation: 8.0,
              child: FutureBuilder(
                future: results,
                builder: (BuildContext context,
                    AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done &&
                      snapshot.hasData == false) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final theme = Theme.of(context);
                  final results = snapshot.requireData;
                  return SingleChildScrollView(
                      child: Column(
                    children: [
                      if (results.isEmpty) //
                        ListTile(
                          title: Text(
                            'No results found',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      for (final result in results) //
                        ListTile(
                          onTap: () {},
                          title: Text(result),
                        ),
                    ],
                  ));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
