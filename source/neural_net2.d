module neural_net2;

import std.math;
import std.stdio;
import std.string;
import std.random;
import std.conv;

import Dgame.Window;
import Dgame.Math;
import Dgame.Graphic;
import Dgame.System.Font;
import Dgame.Graphic.Text;

import util;
import main;

class Net {
private void initWeights(uint[] topology) {
	uint numLayers = topology.length;
	weights = new float[][][numLayers - 1];
	for(int l = 1; l < numLayers; l++) {
		weights[l - 1] = new float[][topology[l]];
		for(int i = 0; i < topology[l]; i++) {
			float sqrtd = 1/(sqrt(cast(float)topology[l]));
			//no bias on output layer
			int numInputs = (l == numLayers - 1) ? topology[l - 1] :
					topology[l - 1] + 1;
			weights[l - 1][i] = new float[numInputs];
			for(int j = 0; j < numInputs; j++) {
				weights[l-1][i][j] = uniform(-sqrtd, sqrtd);
			}
		}
	}
}
public:
	this(uint[] topology, float[][][]* _weights) {
		this.topology = topology;
		uint numLayers = topology.length;
		
		if(_weights) {
			weights = *_weights;
		} else {
			initWeights(topology);
		}

		outputs = new float[][numLayers];
		for(int l = 0; l < numLayers; l++) {
			outputs[l] = new float[topology[l]];
			for(int i = 0; i < topology[l]; i++) {
				outputs[l][i] = 0;
			}
		}

		//debug
		font = Font("resources/Lucida Console.ttf", 12);
		smallCircle = new Shape(NEURON_RADIUS - 1, Vector2f(0,0));
		circle = new Shape(NEURON_RADIUS, Vector2f(0,0));
		text = new Text(font);
		text.foreground = Color4b(0,0,0);
		text.background = Color4b(255,255,255,0);
	}

	float[] evaluate(float[] inputValues) {
		assert(inputValues.length == topology[0]);
		for(int i = 0; i < inputValues.length; i++) {
			outputs[0][i] = inputValues[i];
		}

		for(int l = 1; l < weights.length + 1; l++) {
			for(int i = 0; i < weights[l - 1].length; i++) {
				float sum = 0;
				for(int j = 0; j < outputs[l - 1].length; j++) {
					sum += outputs[l - 1][j] * weights[l-1][i][j];
				}
				//if not the output layer
				if(l != weights.length) {
					//add bias
					sum += weights[l-1][i][weights[l-1][i].length - 1];
				}
				outputs[l][i] = sigmoid(sum);
			}
		}

		return outputs[outputs.length - 1];
	}

	@nogc
	private float sigmoid(float x) {
		return 2.0/(1 + exp(-x)) - 1;
		//return 1.0/(1 + exp(-x));
	}

	void visualize(ref Window window, int x, int y) {
		Vector2f transform = Vector2f(x,y);
		for(int l = 0; l < weights.length; l++) {
			for(int i = 0; i < weights[l].length; i++) {
				Vertex curentVert = Vertex(getNeuronPosition(l + 1, i) + transform);
				for(int j = 0; j < weights[l][i].length; j++) {
					line = new Shape(Geometry.Lines, [
							curentVert, 
							Vertex(getNeuronPosition(l, j) + transform)
						]);
					float _weight = weights[l][i][j];
					line.setColor(
							_weight >= 0 ? posLerp.lerp(_weight) : 
							negLerp.lerp(-_weight)
						);
					window.draw(line);
				}
			}
		}
		for(int l = 0; l < topology.length; l++) {
			for(int i = 0; i < topology[l]; i++) {
				circle.setPosition(getNeuronPosition(l,i) + transform);
				window.draw(circle);
			}
		}

		for(int l = 0; l < topology.length; l++) {
			for(int i = 0; i < topology[l]; i++) {
				smallCircle.setPosition(getNeuronPosition(l,i) + transform);
				float _output = outputs[l][i];
				smallCircle.setColor(
						_output >= 0 ? posLerp.lerp(_output) : 
						negLerp.lerp(-_output)
					);
				window.draw(smallCircle);
				text.setPosition(getNeuronPosition(l,i) + transform
						+Vector2f(0,2));
				text.format("%s", to!string(_output));
				window.draw(text);
			}
		}
	}

	void handleMouseInput(Vector2i position) {
		int _x = cast(int)round(getNeuronPosition(0,0).x);
		if(position.x < _x + NEURON_RADIUS && position.x > _x - NEURON_RADIUS) {
			for(int i = 0; i < topology[0] + 1; i++) {
				int _y = (i == topology[0]) ? -1 : cast(int)round(getNeuronPosition(0, i).y);
				if(position.y < _y + NEURON_RADIUS && position.y > _y - NEURON_RADIUS || _y == -1) {
					float[] inputs = new float[topology[0]];
					for(int j = 0; j < topology[0]; j++) {
						inputs[j] = (j != i || _y == -1) ? 0 : 1;
					}

					evaluate(inputs);
					return;
				}
			}
		}
	}

	float[][][] getWeights() {
		return weights;
	}

private:
	static const int DEBUG_WIDTH = 300;
	static const int DEBUG_HEIGHT = 400;
	static const int DEBUG_MARGIN = 40;
	static const int NEURON_RADIUS = 15;
	Vector2f getNeuronPosition(int x, int y) {
		assert(x >= 0 && x < topology.length,
				format("index out of range %s, %s", x, y));
		float _x = ((DEBUG_WIDTH - 2 * DEBUG_MARGIN) / (topology.length - 1)) * x + DEBUG_MARGIN;

		int shapeMax = 0;
		for(int i = 0; i < topology.length; i++) {
			if(topology[i] > shapeMax) {
				shapeMax = topology[i];
			}
		}

		float y_interval = (DEBUG_HEIGHT / (shapeMax + 1));
		float _y = y_interval * (y + 1) 
				+ y_interval * .5 * (shapeMax - topology[x]);

		return Vector2f(_x,_y);
	}

private:
	uint[] topology;
	float[][] outputs;
	float[][][] weights;

	Gradient posLerp = new Gradient(Color4b(255,255,255), Color4b(0,255,0));
	Gradient negLerp = new Gradient(Color4b(255,255,255), Color4b(255,0,0));

	Font font;
	Shape circle;
	Shape smallCircle;
	Shape line;
	Text text;
}