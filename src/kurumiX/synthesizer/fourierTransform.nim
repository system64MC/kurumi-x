import fft
import math, complex

proc fourierTransform*(data: ptr array[4096 * 8, float64], length: int): void =

    var arrIn = newSeq[complex.Complex64](length)
    var arrOut = newSeq[complex.Complex64](length)

    # var kfft = newKissFFT(length, false)
    # var kIfft = newKissFFT(length, true)

    for i in 0..<length:
        let smp = data[i]
        arrIn[i] = complex.Complex64(re: smp.float64)

    arrOut = arrIn.FFT()

    # kfft.transform(arrIn, arrOut)

    for c in 17..<length:
        arrOut[c].im = 0
        arrOut[c].re = 0

    arrIn = IFFT(arrOut)

    # kIfft.transform(arrOut, arrIn)

    for i in 0..<length:
        data[i] = arrIn[i].re.float64