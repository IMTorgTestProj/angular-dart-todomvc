library todo;

import 'dart:html' as dom;
import 'dart:convert' as convert;
import 'package:angular/angular.dart';


class StorageService {
	final dom.Storage _storage = dom.window.localStorage;
	static const String STORAGE_KEY = "todomvc_dartangular";

	List<Item> loadItems() {
		final String data = _storage[STORAGE_KEY];

		if (data == null) {
			return [];
		}

		final List<Map> rawItems = convert.JSON.decode(data);
		return rawItems.map((item) => new Item.fromJson(item)).toList();
	}

	void saveItems(List<Item> items) {
		_storage[STORAGE_KEY] = convert.JSON.encode(items);
	}
}


class Item {
	String title;
	bool done;
	
	Item([String this.title = '', bool this.done = false]);
	
	Item.fromJson(Map obj) {
		this.title = obj["title"];
		this.done = obj["done"];
	}

	bool get isEmpty => title.trim().isEmpty;

	Item clone() => new Item(this.title, this.done);

	String toString() => done ? "[X]" : "[ ]" + " ${this.title}";

	void normalize() {
		title = title.trim();
	}

	// This is method is called when from JSON.encode.
	Map toJson() => { "title": title, "done": done };
}


@NgDirective(
	selector: '[todo-controller]',
	publishAs: 'todo'
)
class TodoController {
	List<Item> items = [];
	Item newItem = new Item();
	Item editedItem = null;
	Item previousItem = null;
	
	TodoController(Scope scope, StorageService storage) {
		items = storage.loadItems();
		scope.$watchCollection('todo.items', (collection) {
			print("Saving collection.");
			storage.saveItems(collection);
		});
	}

	void add() {
		if (!newItem.isEmpty) {
			newItem.normalize();
			items.add(newItem);
			newItem = new Item();
		} else {
			print("Item is empty: " + newItem.title);
		}
	}
	
	void remove(Item item) {
		items.remove(item);
	}
	
	void clearCompleted() {
		items.removeWhere((i) => i.done);
	}
	
	int remaining() {
		return items.where((item) => !item.done).length;
	}
	
	int completed() {
		return items.where((item) => item.done).length;
	}
	
	int total() {
		return items.length;
	}
	
	bool get allChecked {
		return items.every((i) => i.done);
	}
	
	void set allChecked(value) {
		items.forEach((i) => i.done = value);
	}
	
	String get itemsLeftText {
		return 'item' + (remaining() != 1 ? 's' : '') + ' left';
	}

	void editTodo(Item item) {
		editedItem = item;
		previousItem = item.clone();
	}

	void doneEditing() {
		if (editedItem == null) {
			return;
		}

		if (editedItem.isEmpty) {
			items.remove(editedItem);
		}

		editedItem.normalize();
		editedItem = null;
		previousItem = null;
	}

	void revertEditing(Item item) {
		editedItem = null;
		item.title = previousItem.title;
		previousItem = null;
	}
}