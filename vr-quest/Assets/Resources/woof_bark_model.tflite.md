# TFLite Bark Model Placeholder

**Model:** woof_bark_model.tflite
**Input shape:** [1, 1, 1024, 1] Float32
**Output shape:** [1, 4] Float32 (bark, howl, whine, silence)

## Conversion Instructions

To convert the Phase 38 CoreML model to TFLite format:

1. **CoreML to ONNX:**
   ```bash
   pip install coremltools>=7.0
   python -c "import coremltools as ct; model = ct.models.MLModel('path/to/model.mlmodel'); spec = model.get_spec(); ct.utils.save_spec(spec, 'bark_detector.onnx')"
   ```

2. **ONNX to TFLite:**
   ```bash
   pip install onnx onnx-tf
   ```

3. **Place the resulting .tflite file at:**
   ```
   vr-quest/Assets/Resources/woof_bark_model.tflite
   ```

## Status

Placeholder file created. The BarkDetector uses a mock classifier fallback when the model is not present.

## Notes

- The BarkClassifier class handles graceful fallback to mock classification when model loading fails
- Confidence threshold is 0.7f, debounce is 1.0s (configured in BarkDetector)
- The mock classifier uses a simple energy-based heuristic for early testing
