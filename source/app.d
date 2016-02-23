module main;

import std.stdio;
import std.random;
import std.math;

import Dgame.Window;
import Dgame.Graphic;
import Dgame.Math;
import Dgame.System.Keyboard;
import Dgame.System.StopWatch;
import Dgame.System.Font;
import Dgame.Graphic.Text;

import fish;
import pile_gc;
import util;
import unit_test;

const uint WINDOW_WIDTH = 800;
const uint WINDOW_HEIGHT = 600;
const uint MAX_POPULATION = 2;
const uint GRID_SIZE = 10;
const uint FOOD_RADIUS = 10;

pileTemplate!(Fish*).Pile* fishes;
pileTemplate!(Vector2f*).Pile* food;
ubyte[WINDOW_WIDTH / GRID_SIZE][WINDOW_HEIGHT / GRID_SIZE] scent;

bool updateScent = false;

private:
Shape tile;
Shape foodSprite;
void main() {
	test();
	Window wnd = Window(WINDOW_WIDTH, WINDOW_HEIGHT, "Dgame Test", 
			Window.Style.Default, 
			GLContextSettings(GLContextSettings.AntiAlias.X8));
	wnd.setVerticalSync(Window.VerticalSync.Enable);

	Font font = Font("resources/Lucida Console.ttf", 12);
	StopWatch clock;
	ulong frames = 0;
	Text currentFPS = new Text(font);
	currentFPS.background = Color4b(0,0,0,0);
	currentFPS.foreground = Color4b(255,255,255);
	ulong realFPS = 0;

	fishes = new pileTemplate!(Fish*).Pile(MAX_POPULATION);

	for(int i = 0; i < MAX_POPULATION; i++) {
		fishes.add(new fish.Fish("test", &wnd, WINDOW_WIDTH, WINDOW_HEIGHT));
	}

	food = new pileTemplate!(Vector2f*).Pile(100);
	for(int i = 0; i < 20; i++) {
		food.add(new Vector2f(
				uniform(FOOD_RADIUS, WINDOW_WIDTH - FOOD_RADIUS),
				uniform(FOOD_RADIUS, WINDOW_HEIGHT - FOOD_RADIUS)));
	}

	bakeScent();

	tile = new Shape(Geometry.Quads, 
			[Vertex(0,0), 
			Vertex(GRID_SIZE,0), 
			Vertex(GRID_SIZE,GRID_SIZE),
			Vertex(0,GRID_SIZE)]);
	foodSprite = new Shape(FOOD_RADIUS, Vector2f(0,0));
	foodSprite.setColor(Color4b.Red);
	
	bool running = true;
	Event event;
	while (running) {
		wnd.clear();
		
		while (wnd.poll(&event)) {
			switch (event.type) {
				case Event.Type.Quit:
					writeln("Quit Event");
					running = false;
				break;
					
				case Event.Type.KeyDown:
					writeln("Pressed key ", event.keyboard.key);
					
					if (event.keyboard.key == Keyboard.Key.Esc){
						running = false; // or: wnd.push(Event.Type.Quit);
					}
					
				break;
				
				default: break;
			}
		}

		if(updateScent) {
			bakeScent();
		}

		//draw scent
		for(int y = 0; y < scent.length; y++) {
			for(int x = 0; x < scent[0].length; x++) {
				tile.setPosition(cast(float) (x * GRID_SIZE),
								 cast(float) (y * GRID_SIZE));
				ubyte color = scent[y][x];
				tile.setColor(Color4b(0, 0, color));
				wnd.draw(tile);
			}
		}

		//draw food
		food.itr_start();
		while(food.itr_hasNext()) {
			auto _food = food.itr_next();
			
			foodSprite.setPosition(*_food);
			wnd.draw(foodSprite);
		}
		food.itr_done();
		
		fishes.itr_start();
		while(fishes.itr_hasNext()) {
			auto _fish = fishes.itr_next();
			assert(_fish != null);
			if(_fish.simulate()) {
				fishes.itr_remove();
			}
		}
		fishes.itr_done();

		/*auto elapsed = clock.getElapsedTicks();
		frames++;
		if(elapsed >= 1000) {
			realFPS = frames;

			frames = 0;
			clock.reset();
		}*/

		currentFPS.format("FPS: %d", realFPS);
		
		wnd.draw(currentFPS);

		wnd.display();
	}
}

void bakeScent() {
	for(int y = 0; y < scent.length; y++) {
		for(int x = 0; x < scent[0].length; x++) {
			scent[y][x] = 0;
		}
	}

	food.itr_start();
	while(food.itr_hasNext()) {
		auto a = food.itr_next();

		int food_x_grid = cast(int)round(a.x/GRID_SIZE);
		int food_y_grid = cast(int)round(a.y/GRID_SIZE);

		int y_min = max(food_y_grid - 10, 0);
		int y_max = min(food_y_grid + 10, scent.length);
		int x_min = max(food_x_grid - 10, 0);
		int x_max = min(food_x_grid + 10, scent[0].length);


		for(int y = y_min; y < y_max; y++) {
			for(int x = x_min; x < x_max; x++) {
				int distance = cast(int)round(sqrt(cast(float)
						((x - food_x_grid)*(x - food_x_grid) +
						(y - food_y_grid)*(y - food_y_grid))
					));
				distance = max(distance, 0);
				
				int addValue = 255 - (distance * 255/10);
					addValue = max(addValue, 0);

				int tileValue = cast(int)scent[y][x];
					tileValue += addValue;
					tileValue = min(255, tileValue);
					tileValue = max(0, tileValue);
				scent[y][x] = cast(ubyte) tileValue;
			}
		}
	}
	food.itr_done();
}