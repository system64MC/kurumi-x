import math
import complex
import math

const
  N = 64

proc printWaveform(waveform: array[0..N-1, float]): void =
  for i in 0 .. N-1:
    echo waveform[i]
  echo ""

proc printMagnitudeSpectrum(transformed: array[0..N-1, Complex]) =
  for i in 0 .. N-1:
    echo transformed[i].abs
  echo ""

proc FourierTransform(waveform: array[0..N-1, float]; transformed: var array[0..N-1, Complex]) =
  for k in 0 .. N-1:
    var sum = Complex(0.0, 0.0)
    for n in 0 .. N-1:
      var angle = 2 * PI * k * n / N
      var term = Complex(math.cos(angle), -math.sin(angle))
      sum += waveform[n] * term
    transformed[k] = sum

proc InverseFourierTransform(transformed: array[0..N-1, Complex]; reconstructed: var array[0..N-1, float]) =
  for n in 0 .. N-1:
    var sum = Complex(0.0, 0.0)
    for k in 0 .. N-1:
      var angle = 2 * PI * k * n / N
      var term = Complex(math.cos(angle), math.sin(angle))
      sum += transformed[k] * term
    reconstructed[n] = sum.real / N

var waveform: array[0..N-1, float]

# Generate a waveform example with 64 floats
for i in 0 .. N-1:
  waveform[i] = 3

var transformed: array[0..N-1, Complex]
FourierTransform(waveform, transformed)

# Keep the first 32 frequencies and set the rest to zero
for i in 32 .. N-1:
  transformed[i] = Complex(0.0, 0.0)

var reconstructed: array[0..N-1, float]
InverseFourierTransform(transformed, reconstructed)

var echoed: array[0..(N*2)-1, float]
for i in 0 .. N-1:
  echoed[i] = reconstructed[i]
  echoed[i + N] = reconstructed[i]

# Print the original waveform, the echoed waveform, and their Fourier transforms
echo "Original Waveform:"
printWaveform(waveform)

echo "Fourier Transform (Magnitude):"
printMagnitudeSpectrum(transformed)

echo "Reconstructed Waveform:"
printWaveform(reconstructed)

echo "Echoed Waveform:"
printWaveform(echoed)
