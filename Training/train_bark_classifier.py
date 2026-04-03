#!/usr/bin/env python3
"""
Training script for DogBarkClassifier Core ML model.

This script creates a placeholder model with correct input/output signatures.
For production, replace with a properly trained CNN on mel-spectrogram features.
"""
import sys
import os

# Try to import coremltools, provide helpful error if missing
try:
    import coremltools as ct
    import numpy as np
except ImportError as e:
    print("ERROR: coremltools or numpy not installed")
    print("Install with: pip install coremltools numpy")
    sys.exit(1)

# Define a minimal model: single dense layer (for placeholder only)
# Real model would use CNN on mel-spectrograms
input_dim = 1024
num_classes = 4  # bark, howl, whine, silence

# Create simple linear model as placeholder
weights = np.random.randn(input_dim, num_classes).astype(np.float32) * 0.01
bias = np.random.randn(num_classes).astype(np.float32)

# Save as Core ML model
mlmodel = ct.models.neural_network.NeuralNetworkClassifier(
    input_name="audioBuffer",
    output_name="classProbabilities",
    class_labels=["bark", "howl", "whine", "silence"]
)

# Add a single inner product layer
mlmodel.add_inner_product(
    W=weights,
    b=bias,
    input_channels=input_dim,
    output_channels=num_classes,
    has_bias=True
)

# Specify input shape
mlmodel.input_description = {"audioBuffer": "Audio buffer of 1024 samples"}
mlmodel.output_description = {"classProbabilities": "Probabilities for 4 classes"}

# Output path
output_path = os.path.join(os.path.dirname(__file__), "DogBarkClassifier.mlmodel")
mlmodel.save(output_path)
print(f"Placeholder model created at: {output_path}")
print("WARNING: This model has random accuracy (~25% for 4 classes).")
print("For production, train a CNN on dog sound datasets (AudioSet, ESC-50).")
