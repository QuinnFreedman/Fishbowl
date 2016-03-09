module main;

import std.stdio;
import std.random;
import std.math;
import core.thread;

import Dgame.Window;
import Dgame.Graphic;
import Dgame.Math;
import Dgame.System.Keyboard;
import Dgame.System.StopWatch;
import Dgame.System.Font;
import Dgame.Graphic.Text;

import fish;
import util;
import neural_net2;

const uint WINDOW_WIDTH = 1005;
const uint SIDEBAR_WIDTH = 330;
const uint WINDOW_HEIGHT = 690;
const uint MAX_POPULATION = 20;
const uint FOOD_AMOUNT = 20;
const uint GRID_SIZE = 15;
const uint FOOD_RADIUS = 10;
const uint NUM_TO_REPRODUCE = 6;
const ubyte FPS = 30;
const ubyte TICKS_PER_FRAME = 1000 / FPS;
	  float E4;// = 1/exp(4.0);

static assert(NUM_TO_REPRODUCE % 2 == 0);
static assert(WINDOW_WIDTH % GRID_SIZE == 0);
static assert(WINDOW_HEIGHT % GRID_SIZE == 0);

Fish*[] fishes;
Vector2f[] food;
ubyte[WINDOW_WIDTH / GRID_SIZE][WINDOW_HEIGHT / GRID_SIZE] scent;

bool updateScent = false;

bool render = true;
bool paused = false;

private:
	Shape tile;
	Shape foodSprite;
	Fish* selectedFish = null;
	Vector2i clickLocation;
	Fish*[NUM_TO_REPRODUCE] survivors = new Fish*[NUM_TO_REPRODUCE];
	uint suirvivingIndex = 0;
	uint generation = 0;
	Window wnd;
	ulong ticks = 0;
	ulong meanSurvivorship = 0;
	ulong median = 0;
	uint numSurviving = MAX_POPULATION;
	Object numSurviving_mutex;

void main() {
	//init values
	numSurviving_mutex = new Object;
	E4 = 1.0/exp(4.0);

	wnd = Window(WINDOW_WIDTH + SIDEBAR_WIDTH, WINDOW_HEIGHT,
			"Fishbowl", 
			Window.Style.Default, 
			GLContextSettings(GLContextSettings.AntiAlias.X8));
	wnd.setVerticalSync(Window.VerticalSync.Enable);

	Font font = Font("resources/Lucida Console.ttf", 12);
	StopWatch clock;
	StopWatch sw;
	ulong frames = 0;
	Text currentFPS = new Text(font);
	currentFPS.background = Color4b(0,0,0,0);
	currentFPS.foreground = Color4b(255,255,255);
	ulong realFPS = 0;

	clickLocation = Vector2i(-1,-1);

	fishes = new Fish*[MAX_POPULATION];
	for(int i = 0; i < MAX_POPULATION; i++) {
		fishes[i] = new fish.Fish(null, &wnd, WINDOW_WIDTH, WINDOW_HEIGHT);
	}

	food = new Vector2f[FOOD_AMOUNT];
	for(int i = 0; i < FOOD_AMOUNT; i++) {
		food[i] = Vector2f(
				uniform(FOOD_RADIUS, WINDOW_WIDTH - FOOD_RADIUS),
				uniform(FOOD_RADIUS, WINDOW_HEIGHT - FOOD_RADIUS));
	}

	bakeScent();

	tile = new Shape(Geometry.Quads, 
			[Vertex(0,0), 
			Vertex(GRID_SIZE,0), 
			Vertex(GRID_SIZE,GRID_SIZE),
			Vertex(0,GRID_SIZE)]);
	foodSprite = new Shape(FOOD_RADIUS, Vector2f(0,0));
	foodSprite.setColor(Color4b.Red);
	

	Vector2i networkInspectClickPosition = Vector2i(-1, -1);
	bool debugNetwork = false;

	writeln("generation, median, mean, max");				
	bool running = true;
	Event event;
	while (running) {
		while (wnd.poll(&event)) {
			switch (event.type) {
				case Event.Type.Quit:
					writeln("Quit Event");
					running = false;
				break;
					
				case Event.Type.KeyDown:
					if (event.keyboard.key == Keyboard.Key.Esc && !paused){
						render = !render;
						wnd.setVerticalSync(render ? 
								Window.VerticalSync.Enable : 
								Window.VerticalSync.Disable);
					} else if(event.keyboard.key == Keyboard.Key.P) {
						paused = !paused;
					}
					
				break;

				case Event.Type.MouseButtonDown:
					if(event.mouse.button.x < WINDOW_WIDTH) {
						clickLocation.x = event.mouse.button.x;
						clickLocation.y = event.mouse.button.y;
					} else {
						networkInspectClickPosition.x = event.mouse.button.x - WINDOW_WIDTH;
						networkInspectClickPosition.y = event.mouse.button.y;
						debugNetwork = true;
					}


				break;

				case Event.Type.MouseButtonUp:
					debugNetwork = false;

				break;
				
				default: break;
			}
		}

		if(paused) {
			Thread.sleep(dur!("msecs")(2000));
			continue;
		}

		if (sw.getElapsedTicks() <= TICKS_PER_FRAME && render) {
			continue;
		}
		sw.reset();

		if(updateScent) {
			bakeScent();
		}

		//draw scent
		if(render) {
			wnd.clear();
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
			for(int i = 0; i < food.length; i++) {
				foodSprite.setPosition(food[i]);
				wnd.draw(foodSprite);
			}
		}
		
		ticks++;
		for(int i = 0; i < fishes.length; i++) {
			Fish* _fish = fishes[i];
			
			if(_fish.simulate(ticks)) {
				if(--numSurviving < NUM_TO_REPRODUCE) {
					survivors[suirvivingIndex++] = _fish;
				}
				if(numSurviving == MAX_POPULATION/2) {
					median = ticks;
				}

				meanSurvivorship += ticks;
				if(numSurviving == 0) {
					float mean = cast(float)meanSurvivorship/cast(float)MAX_POPULATION;
					writeln(generation, ", ", median, ", ", mean, ", ", ticks);
					ticks = 0;
					meanSurvivorship = 0;

					repopulate();

				}

			}

			if(_fish.alive) {

				if(render) {
					_fish.render();
				}

				if(clickLocation.x != -1) {
					if(clickLocation.x > _fish.getX() - Fish.BODY_RADIUS &&
							clickLocation.x < _fish.getX() + Fish.BODY_RADIUS &&
							clickLocation.y > _fish.getY() - Fish.BODY_RADIUS &&
							clickLocation.y < _fish.getY() + Fish.BODY_RADIUS
						){
						selectedFish = _fish;
						clickLocation.x = -1;
					}
				} else if(!selectedFish) {
					selectedFish = _fish;
				}
			}
		}

		if(render){

			if(debugNetwork) {
				assert(selectedFish != null) ;

				selectedFish.getBrain().handleMouseInput(
						networkInspectClickPosition);
			}

			selectedFish.drawBrain(wnd, WINDOW_WIDTH, 0);
		
			currentFPS.format("FPS: %d", clock.getCurrentFPS());
			
			wnd.draw(currentFPS);

			wnd.display();
		}
	}
}

float expDecay(float x) {
	return exp(-4 * x) - E4 * x;
}

const float SCENT_RADIUS = 15;
void bakeScent() {
	for(int y = 0; y < scent.length; y++) {
		for(int x = 0; x < scent[0].length; x++) {
			scent[y][x] = 0;
		}
	}

	for(int i = 0; i < food.length; i++) {
		int food_x_grid = cast(int)round((food[i].x - GRID_SIZE/2)/GRID_SIZE);
		int food_y_grid = cast(int)round((food[i].y - GRID_SIZE/2)/GRID_SIZE);

		int y_min = max(food_y_grid - cast(int)SCENT_RADIUS, 0);
		int y_max = min(food_y_grid + cast(int)SCENT_RADIUS, scent.length);
		int x_min = max(food_x_grid - cast(int)SCENT_RADIUS, 0);
		int x_max = min(food_x_grid + cast(int)SCENT_RADIUS, scent[0].length);


		for(int y = y_min; y < y_max; y++) {
			for(int x = x_min; x < x_max; x++) {
				float distance = sqrt(cast(float)
						((x - food_x_grid)*(x - food_x_grid) +
						(y - food_y_grid)*(y - food_y_grid))
					);

				distance = maxf(distance, 0.0) * GRID_SIZE/SCENT_RADIUS;
				
				float normalizedDistance = distance/SCENT_RADIUS;

				int addValue = cast(int)(expDecay(normalizedDistance) * 255);
					addValue = max(addValue, 0);

				int tileValue = cast(int)scent[y][x];
					tileValue += addValue;
					tileValue = min(255, tileValue);
					tileValue = max(0, tileValue);
				scent[y][x] = cast(ubyte) tileValue;
			}
		}
	}
}

void repopulate() {
	generation++;
	suirvivingIndex = 0;
	float avgNumChildren = cast(float)MAX_POPULATION/NUM_TO_REPRODUCE;
	int index = 0;
	for(int i = 0; i < NUM_TO_REPRODUCE; i+=2) {
		int numChildren = cast(int)round(i * avgNumChildren);
		for(int child = 0; child < numChildren; child++) {
			fishes[index++] = cross(*(survivors[i]), *(survivors[i + 1]));
		}
		survivors[i] = null;
		survivors[i + 1] = null;
	}

	numSurviving = MAX_POPULATION;

	for(int i = 0; i < FOOD_AMOUNT; i++) {
		food[i] = Vector2f(
				uniform(FOOD_RADIUS, WINDOW_WIDTH - FOOD_RADIUS),
				uniform(FOOD_RADIUS, WINDOW_HEIGHT - FOOD_RADIUS));
	}
	bakeScent();
}

Fish* cross(ref Fish a, ref Fish b) {
	bool crossOver = false;
	auto a_weights = a.getBrain().getWeights();
	auto b_weights = a.getBrain().getWeights();

	float[][][] childWeights;

	assert(a_weights.length == b_weights.length);
	childWeights = new float[][][a_weights.length];

	for(int l = 0; l < a_weights.length; l++) {
		assert(a_weights[l].length == b_weights[l].length);
		childWeights[l] = new float[][a_weights[l].length];

		for(int i = 0; i < a_weights[l].length; i++) {
			assert(a_weights[l][i].length == b_weights[l][i].length);
			childWeights[l][i] = new float[a_weights[l][i].length];

			for(int j = 0; j < a_weights[l][i].length; j++) {

				if(uniform(0,9) < 1) {
					crossOver = !crossOver;
				}
				childWeights[l][i][j] = crossOver ? a_weights[l][i][j] : 
													b_weights[l][i][j];
				if(uniform(0,4) < 1) {
					childWeights[l][i][j] += .25 * box_muller(0, 1);
				}
			}
		}
	}

	return new Fish(&childWeights, &wnd, WINDOW_WIDTH, WINDOW_HEIGHT);
}