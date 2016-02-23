module pile;

import std.stdio;
import core.memory;
import core.exception;

template pileTemplate(T) {
	struct Pile {
		private T* data;
		private int used_size;
		private int capacity;
		private bool isIterating;

		alias free = core.stdc.stdlib.free;
		private static void* malloc(int used_size) {
			auto p = core.stdc.stdlib.malloc(used_size);
			if(!p) {
				onOutOfMemoryError();
			}
			return p;
		}

		@nogc
		this(int capacity) {
			assert(capacity > 0, "Invalid capacity");
			data = cast(T*)malloc(capacity * T.sizeof);
			this.capacity = capacity;
			this.used_size = 0;
			isIterating = false;
		}

		@nogc
		int size() {
			return this.used_size;
		}

		@nogc
		void add(T element) {
			if(used_size + 1 >= capacity) {
				ensureCapacity((used_size + 1) * 2);
			}
			data[used_size] = element;
			used_size++;
		}

		@nogc
		void clear() {
			used_size = 0;
			data = cast(T*)malloc(capacity * T.sizeof);
		}

		@nogc
		void ensureCapacity(int newCapacity) {
			if(capacity < newCapacity) {
				T* newData = cast(T*)malloc(newCapacity * T.sizeof);
				for(int i = 0; i < used_size; i++) {
					newData[i] = data[i];
				}
				free(data);
				data = newData;
				capacity = newCapacity;
			}
		}

		@nogc
		bool contains(T e) {
			for(int i = 0; i < used_size; i++) {
				if(data[i] == e) {
					return true;
				}
			}

			return false;
		}

		/* iterator */
		private int _itr_index;

		@nogc
		void itr_start() {
			assert(!isIterating, "Error: concurrent iteration");

			isIterating = true;
			_itr_index = 0;
		}

		@nogc
		T itr_next() {
			assert(isIterating && _itr_index < used_size, "Not iterating");

			return data[_itr_index++];
		}

		@nogc
		bool itr_hasNext() {
			assert(isIterating, "Not iterating");

			return (_itr_index < used_size);
		}
		
		@nogc
		void itr_remove() {
			assert(isIterating, "Not iterating");

			_itr_index--;
			data[_itr_index] = data[used_size - 1];
			used_size--;
		}

		@nogc
		void itr_done() {
			assert(isIterating, "Not iterating");

			isIterating = false;
		}

		/* iterator end */
	}
};