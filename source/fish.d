module fish;

import std.stdio;
import std.math;
import std.random;
import Dgame.Graphic;
import Dgame.Math;
import Dgame.Window;

import NeuralNetwork;
import main;
import util;

private const RAD_TO_DEG = 57.2957795131;

struct Fish {
	public:
		this(string genome, Window* window, int window_width, int window_height) {
			this.genome = genome;
			this.window = window;
			position = Vector2f(300, 250);
			circle = new Shape(BODY_RADIUS, Vector2f(0, 0));
			circle.setColor(Color4b(10,200,10));
			antennaTip1 = new Shape(5, Vector2f(0, 0));
			antennaTip1.setColor(Color4b.Gray);
			antennaTip2 = new Shape(5, Vector2f(0, 0));
			antennaTip2.setColor(Color4b.Gray);
			window.draw(circle);
			brain = NeuralNetwork.NeuralNet([2, 5, 4, 3]);
			facing = uniform(0, 2 * PI);
			alive = true;
			health = 600;
		}

		bool simulate() {
			health--;
			if(health <= 0) {
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

		//	calculate
			int turnDir = 0;
			if(raw_input_antenna1 > raw_input_antenna2) {
				turnDir = 1;
			} else if(raw_input_antenna1 < raw_input_antenna2) {
				turnDir = -1;
			}
		//	move
			changeSpeed(0.1);
			changeRotSpeed(0.04 * turnDir);
			transform();

		//	check food
			//TODO tighten up
			if(scent[bound(cast(int)round(position.y/GRID_SIZE), 0, scent.length - 1)]
					[bound(cast(int)round(position.x/GRID_SIZE), 0, scent[0].length - 1)] > 200) {
				food.itr_start();
				while (food.itr_hasNext()) {
					Vector2f* a = food.itr_next();
					if(sqrt((a.x - position.x) * (a.x - position.x) + 
							(a.y - position.y) * (a.y - position.y)) < 
							FOOD_RADIUS + BODY_RADIUS) {
						health += 200;
						a.x = uniform(0 + FOOD_RADIUS, WINDOW_WIDTH + FOOD_RADIUS);
						a.y = uniform(0 + FOOD_RADIUS, WINDOW_HEIGHT + FOOD_RADIUS);
						updateScent = true;
						break;
					}
				}
				food.itr_done();
			}

		//	render
			circle.setPosition(position);
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
			return false;
		}

	private:
		string genome;
		Shape circle;
		Shape tail;
		Shape antenna1;
		Shape antenna2;
		Shape antennaTip1;
		Shape antennaTip2;
		Window* window;
		NeuralNetwork.NeuralNet brain;
		float facing;
		float speed = 0;
		float rotSpeed = 0;
		Vector2f position;
		Vector2f v_tail = Vector2f(0,0);
		Vector2f v_antenna1 = Vector2f(0,0);
		Vector2f v_antenna2 = Vector2f(0,0);
		bool alive;
		//int food;
		int health;
		const float ANTENNA_SPLAY_RAD = .7;
		const int ANTENNA_LENGTH = 40;
		const float MAX_SPEED = 1; //5;
		const float MAX_ROT_SPEED = 0.04;
		const float MAX_ACCELERATION = MAX_SPEED / 10;
		const float MAX_ROT_ACCELERATION = MAX_ROT_SPEED / 10;
		const float TWO_PI = 2 * PI;
		const int BODY_RADIUS = 25;

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