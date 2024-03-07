import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories_data.dart';

import 'package:shopping_list/models/grocery_models.dart';
import 'package:shopping_list/widgets/add_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.https(
        'flutter-prep-a237e-default-rtdb.firebaseio.com',
        'string-list.json',
      );
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        throw Exception(
            'Error when fetching the data (Status Code: ${response.statusCode})');
      }

      final Map<String, dynamic>? listData = json.decode(response.body);
      if (listData == null || listData.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final loadedItems = listData.entries.map((item) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        return GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        );
      }).toList();

      setState(() {
        _isLoading = false;
        _groceryItems = loadedItems;
      });
    } on Exception catch (error) {
      setState(() {
        _isLoading = false;
        _error = '$error';
      });
    }
  }

  void _addItem() async {
    final response = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const AddItem(),
      ),
    );

    if (response == null) {
      return;
    }

    setState(
      () {
        _groceryItems.add(response);
      },
    );
  }

  void _removeItem(GroceryItem item) async {
    final indexItem = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('flutter-prep-a237e-default-rtdb.firebaseio.com',
        'string-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Grocery item removed failed',
            ),
          ),
        );
      }
      setState(() {
        _groceryItems.insert(indexItem, item);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).clearMaterialBanners();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: const Text(
        //       'Grocery item removed successfully',
        //     ),
        //     dismissDirection: DismissDirection.up,
        //     behavior: SnackBarBehavior.floating,
        //     margin: EdgeInsets.only(
        //         bottom: MediaQuery.of(context).size.height - 150,
        //         left: 10,
        //         right: 10), // Adjust top margin
        //   ),
        // );
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            backgroundColor: Theme.of(context).colorScheme.onBackground,
            content: const Text('Grocery item removed successfully'),
            actions: const <Widget>[
              TextButton(
                onPressed: null,
                child: Text(''),
              ),
            ],
          ),
        );
        Timer(const Duration(seconds: 2), () {
          ScaffoldMessenger.of(context).clearMaterialBanners();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Upss there is no grocery here...',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Theme.of(context).colorScheme.onBackground),
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            'Try adding some grocery',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Theme.of(context).colorScheme.onBackground),
          ),
        ],
      ),
    );

    if (_isLoading) {
      child = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      child = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      child = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: child,
    );
  }
}
