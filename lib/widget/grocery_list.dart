import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _grecoryitems = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'shopping-app-430d1-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> _loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      _loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _grecoryitems = _loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _grecoryitems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _grecoryitems.indexOf(item);
    setState(() {
      _grecoryitems.remove(item);
    });

    final url = Uri.https(
        'shopping-app-430d1-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _grecoryitems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No Item Added yet'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }
    if (_grecoryitems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _grecoryitems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_grecoryitems[index]);
          },
          key: ValueKey(_grecoryitems[index].id),
          child: ListTile(
            title: Text(_grecoryitems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _grecoryitems[index].category.color,
            ),
            trailing: Text(_grecoryitems[index].quantity.toString()),
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Youre Grocories'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: content);
  }
}
