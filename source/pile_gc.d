module pile_gc;

import std.stdio;
import core.memory;
import core.exception;

template pileTemplate(T) {
	struct Pile {
		private T[] data;
		private int size;
		private int capacity;
		private bool isIterating;

		this(int capacity) {
			if(capacity < 0) {
				throw new Exception("Invalid capacity");
			}	
			data = new T[capacity];
			this.capacity = capacity;
			this.size = 0;
			isIterating = false;
		}

		void add(T element) {
			size++;
			if(size >= capacity) {
				ensureCapacity(size * 2);
			}
			data[size - 1] = element;
		}

		void clear() {
			size = 0;
			data = new T[capacity];
		}

		void ensureCapacity(int newCapacity) {
			if(capacity < newCapacity) {
				T[] newData = new T[newCapacity];
				for(int i = 0; i < size; i++) {
					newData[i] = data[i];
				}
				data = newData;
				capacity = newCapacity;
			}
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
			if(_itr_index >= size) {
				throw new Exception("Not iterating");
			}
			return data[_itr_index++];
		}

		bool itr_hasNext() {
			if(!isIterating) {
				throw new Exception("Not iterating");
			}
			return (_itr_index < size);
		}
		
		void itr_remove() {
			if(!isIterating) {
				throw new Exception("Not iterating");
			}
			_itr_index--;
			data[_itr_index] = data[size - 1];
			size--;
		}

		void itr_done() {
			isIterating = false;
		}

		/* iterator end */
	}
};