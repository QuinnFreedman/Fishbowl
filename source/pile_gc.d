module pile_gc;

import std.stdio;
import core.memory;
import core.exception;

template pileTemplate(T) {
	struct Pile {
		private T[] data;
		private int used_size;
		private int capacity;
		private bool isIterating;

		this(int capacity) {
			if(capacity < 0) {
				throw new Exception("Invalid capacity");
			}	
			data = new T[capacity];
			this.capacity = capacity;
			this.used_size = 0;
			isIterating = false;
		}

		void add(T element) {
			used_size++;
			if(used_size >= capacity) {
				ensureCapacity(used_size * 2);
			}
			data[used_size - 1] = element;
		}

		@nogc
		int size() {
			return this.used_size;
		}

		void clear() {
			used_size = 0;
			data = new T[capacity];
		}

		void ensureCapacity(int newCapacity) {
			if(capacity < newCapacity) {
				T[] newData = new T[newCapacity];
				for(int i = 0; i < used_size; i++) {
					newData[i] = data[i];
				}
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

		void itr_start() {
			if(isIterating) {
				throw new Exception("Error: concurrent iteration");
			}
			isIterating = true;
			_itr_index = 0;
		}

		T itr_next() {
			if(!isIterating) {
				throw new Exception("Not iterating");
			}
			if(_itr_index >= used_size) {
				throw new Exception("Not iterating");
			}
			return data[_itr_index++];
		}

		bool itr_hasNext() {
			if(!isIterating) {
				throw new Exception("Not iterating");
			}
			return (_itr_index < used_size);
		}
		
		void itr_remove() {
			if(!isIterating) {
				throw new Exception("Not iterating");
			}
			_itr_index--;
			data[_itr_index] = data[used_size - 1];
			used_size--;
		}

		void itr_done() {
			isIterating = false;
		}

		/* iterator end */
	}
};