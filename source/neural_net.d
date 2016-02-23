module NeuralNetwork;

import std.math;
import std.random;
import std.stdio;

struct NeuralNet {
	private int[] shape;
	private int layers;
	//private float[] inputs;
	private float[][] outputs;
	float[][][] weights;
	float[][] biases;
	private int numWeights;

	this(int[] shape) {
		this.shape = shape;
		layers = shape.length;
		//this.inputs = new int[shape[0]];
		this.outputs = new float[][layers];

		for(int i = 0; i < layers; i++) {
			this.outputs[i] = new float[shape[i]];
		}

		this.weights = new float[][][layers - 1];
		this.biases = new float[][layers - 1];
		this.numWeights = 0;
		for(int i = 0; i < layers - 1; i++) {
			this.biases[i] = new float[shape[i + 1]];
			this.weights[i] = new float[][shape[i + 1]];
			for(int j = 0; j < weights[i].length; j++) {
				weights[i][j] = new float[shape[i]];
				for(int k = 0; k < weights[i][j].length; k++) {
					numWeights++;
					weights[i][j][k] = 0;
				}
			}
		}
	}

	this(int[] shape, float[][][] newWeights) {
		this(shape);

		for(int i = 0; i < layers - 1; i++) {
			for(int j = 0; j < weights[i].length; j++) {
				for(int k = 0; k < weights[i][j].length; k++) {
					weights[i][j][k] = newWeights[i][j][k];
				}
			}
		}
	}

	float[] evaluate(float[] inputs) {
		assert (inputs.length == this.shape[0]);
		for(int i = 0; i < inputs.length; i++) {
			this.outputs[0][i] = inputs[i];
		}
		for(int l = 1; l < layers; l++) {
			for(int i = 0; i < shape[l]; i++) {
				float functionInput = 0;
				for(int j = 0; j < shape[l - 1]; j++) {
					functionInput += weights[l][i][j] * outputs[l-1][j];
				}
				outputs[l][i] = sigmoid(functionInput);
			}
		}
		return outputs[outputs.length - 1];
	}
}

private const float crossRate;
NeuralNet* crossNetworks(NeuralNet* a, NeuralNet* b) {
	float[][][] weights = new float[][][a.weights.length];
	bool copyFromA = uniform(0,1) < .5;

	for(int l = 0; l < weights.length; l++) {
		for(int i = 0; i < weights[l].length; i++) {
			for(int j = 0; j < weights[l][i].length; j++) {
				writeln(uniform(0,1));
			}
		}
	}

	NeuralNet* network = new NeuralNet([1, 2, 1]);
	return network;
}

private double sigmoid(double x) {
	return 1.0/(1 + exp(-x));
}