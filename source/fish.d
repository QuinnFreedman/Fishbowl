module fish;

import std.stdio;
import std.math;
import std.random;
import Dgame.Graphic;
import Dgame.Math;
import Dgame.Window;

import neural_net2;
import main;
import util;

private const RAD_TO_DEG = 57.2957795131;

struct Fish {
	public:
		static const int BODY_RADIUS = 25;

		this(float[][][]* genome, Window* window, const uint window_width, const uint window_height) {
			this.window = window;
			circle = new Shape(BODY_RADIUS, Vector2f(0, 0));
			//Color4b(10,200,10)
			bodyColor = new Gradient(Color4b(184,150,72), Color4b(0,219,0));
			antennaTip1 = new Shape(5, Vector2f(0, 0));
			antennaTip1.setColor(Color4b.Gray);
			antennaTip2 = new Shape(5, Vector2f(0, 0));
			antennaTip2.setColor(Color4b.Gray);
			//memory = new float[2];
			reset(genome);
		}

		void reset(float[][][]* genome) {
			position = Vector2f(
					uniform(BODY_RADIUS, WINDOW_WIDTH - BODY_RADIUS),
					uniform(BODY_RADIUS, WINDOW_HEIGHT - BODY_RADIUS));
			brain = new Net([2, 3, 3, 2], genome);
			facing = uniform(0, 2 * PI);
			health = 600;
			alive = true;
			/*for(int i = 0; i < memory.length; i++) {
				memory[i] = 0;
			}*/
		}

		//returns true if fish died this tick
		bool simulate(ulong t) {
			if(!alive) {
				return false;
			}

			health--;
			if(health <= 0 && alive) {
				alive = false;
				return true;
			}
		//	get inputs
			float raw_input_antenna1;
			float raw_input_antenna2;

			int y1 = cast(int) round(v_antenna1.y/GRID_SIZE);
			int x1 = cast(int) round(v_antenna1.x/GRID_SIZE);
			if(y1 < 0 || y1 >= scent.length || 
					x1 < 0 || x1 >= scent[0].length){
				raw_input_antenna1 = -1;
			} else {
				raw_input_antenna1 = cast(float)scent[y1][x1] / 255.0;
			}

			int y2 = cast(int) round(v_antenna2.y/GRID_SIZE);
			int x2 = cast(int) round(v_antenna2.x/GRID_SIZE);
			if(y2 < 0 || y2 >= scent.length || 
					x2 < 0 || x2 >= scent[0].length){
				raw_input_antenna2 = -1;
			} else {
				raw_input_antenna2 = cast(float)main.scent[y2][x2] / 255.0;
			}

			float fullness = cast(float)health/MAX_HEALTH;

			//float sinNoise = sin(t * 0.15);

		//	calculate
			/*float[] output = brain.evaluate([raw_input_antenna1,
					raw_input_antenna2, fullness, memory[0], memory[1]]);*/
			float[] output = brain.evaluate([raw_input_antenna1,
					raw_input_antenna2/*, fullness*/]);
			/*float[] output = brain.evaluate([raw_input_antenna1,
					raw_input_antenna2, fullness, //sinNoise,
					normalize(speed, -MAX_SPEED, MAX_SPEED),
					normalize(rotSpeed, -MAX_ROT_SPEED, MAX_ROT_SPEED)]);*/
			//writeln("rotSpeed == ",rotSpeed," MAX_ROT_SPEED = ",MAX_ROT_SPEED," normalize = ",normalize(rotSpeed, -MAX_ROT_SPEED, MAX_ROT_SPEED));
		//	move
			//memory[0] = output[2];
			//memory[1] = output[3];
			homeostasis();
			changeSpeed(output[0] * 2 * MAX_ACCELERATION);
			changeRotSpeed(output[1] * 2 * MAX_ROT_ACCELERATION);
			transform();

		//	check food
			//TODO tighten up
			if(scent[bound(cast(int)round(position.y/GRID_SIZE), 0, scent.length - 1)]
					[bound(cast(int)round(position.x/GRID_SIZE), 0, scent[0].length - 1)] > 130) {
				
				for(int i = 0; i < food.length; i++) {
					Vector2f* a = &food[i];

					if(sqrt((a.x - position.x) * (a.x - position.x) + 
							(a.y - position.y) * (a.y - position.y)) < 
							FOOD_RADIUS + BODY_RADIUS) {
						health += 200;
						if(health > MAX_HEALTH){
							health = MAX_HEALTH;
						}

						a.x = uniform(FOOD_RADIUS, WINDOW_WIDTH - FOOD_RADIUS);
						a.y = uniform(FOOD_RADIUS, WINDOW_HEIGHT - FOOD_RADIUS);
						updateScent = true;
						break;
					}
				}
			}
			return false;
		}

		void render() {

			float fullness = cast(float)health/MAX_HEALTH;

			circle.setPosition(position);
			circle.setColor(bodyColor.lerp(fullness));
			tail = new Shape(Geometry.Lines, 
					[Vertex(position), Vertex(v_tail)]);
			tail.setColor(Color4b.Red);
			antenna1 = new Shape(Geometry.Lines, [
				Vertex(position), Vertex(v_antenna1)]);
			//antenna1.setColor(Color4b.Gray);
			antenna2 = new Shape(Geometry.Lines, [
				Vertex(position), Vertex(v_antenna2)]);
			//antenna2.setColor(Color4b.Gray);
			antennaTip1.setPosition(v_antenna1);
			window.draw(antennaTip1);
			antennaTip2.setPosition(v_antenna2);
			window.draw(antennaTip2);

			window.draw(circle);
			window.draw(tail);
			window.draw(antenna1);
			window.draw(antenna2);
		}

		void drawBrain(ref Window window, uint x, uint y) {
			brain.visualize(window, x, y);
		}

		Net getBrain() {
			return brain;
		}

		float getX() {
			return position.x;
		}
		float getY() {
			return position.y;
		}

	public:
		bool alive;
	private:
		//float[] memory;
		Shape circle;
		Shape tail;
		Shape antenna1;
		Shape antenna2;
		Shape antennaTip1;
		Shape antennaTip2;
		Window* window;
		Net brain;
		float facing;
		float speed = 0;
		float rotSpeed = 0;
		Vector2f position;
		Vector2f v_tail = Vector2f(0,0);
		Vector2f v_antenna1 = Vector2f(0,0);
		Vector2f v_antenna2 = Vector2f(0,0);
		//int food;
		int health;
		Gradient bodyColor;
		const int MAX_HEALTH = 800;
		const float MAX_SPEED = 2; //5;
		const float MAX_ROT_SPEED = 0.04;
		const float HOEOSTASIS_RATIO = 0.1;
		const float MAX_ACCELERATION = MAX_SPEED / 2;
		const float MAX_ROT_ACCELERATION = MAX_ROT_SPEED / 2;
		const float ANTENNA_SPLAY_RAD = .7;
		const int ANTENNA_LENGTH = 40;
		const float TWO_PI = 2 * PI;

		@nogc
		void changeSpeed(float delta) {
			delta = boundf(delta, -MAX_ACCELERATION, MAX_ACCELERATION);
			speed += delta;
			speed = boundf(speed, 0, MAX_SPEED);
		}

		@nogc
		void changeRotSpeed(float delta) {
			rotSpeed += boundf(delta, 
					-MAX_ROT_ACCELERATION, 
					MAX_ROT_ACCELERATION);
			rotSpeed = boundf(rotSpeed, -MAX_ROT_SPEED, MAX_ROT_SPEED);
		}

		@nogc
		void homeostasis() {
			speed *= 1 - HOEOSTASIS_RATIO;
			rotSpeed *= 1 - HOEOSTASIS_RATIO;

			/*if(speed < 0) {
				speed += minf(-speed, HOEOSTASIS_RATIO * MAX_ACCELERATION);
			} else {
				speed -= minf(speed, HOEOSTASIS_RATIO * MAX_ACCELERATION);
			}

			if(rotSpeed < 0) {
				rotSpeed += minf(-rotSpeed, HOEOSTASIS_RATIO * MAX_ROT_ACCELERATION);
			} else {
				rotSpeed -= minf(rotSpeed, HOEOSTASIS_RATIO * MAX_ROT_ACCELERATION);
			}*/
		}

		@nogc
		void transform() {
			float _cos = cos(facing);
			float _sin = sin(facing);
			float dx = _cos * speed;
			float dy = _sin * speed;

			//translate
			position.x += dx;
			position.y += dy;

			position.x = boundf(position.x, 0, WINDOW_WIDTH);
			position.y = boundf(position.y, 0, WINDOW_HEIGHT);

			//rotate
			facing += rotSpeed;
			if(facing < 0) {
				facing += TWO_PI;
			} else if(facing > TWO_PI) {
				facing -= TWO_PI;
			}

			//rotate antenna
			v_tail.x = position.x + (_cos * -50);
			v_tail.y = position.y + (_sin * -50);

			_cos = cos(facing + ANTENNA_SPLAY_RAD);
			_sin = sin(facing + ANTENNA_SPLAY_RAD);
			v_antenna1.x = position.x + (_cos * ANTENNA_LENGTH);
			v_antenna1.y = position.y + (_sin * ANTENNA_LENGTH);


			_cos = cos(facing - ANTENNA_SPLAY_RAD);
			_sin = sin(facing - ANTENNA_SPLAY_RAD);
			v_antenna2.x = position.x + (_cos * ANTENNA_LENGTH);
			v_antenna2.y = position.y + (_sin * ANTENNA_LENGTH);
		}
}