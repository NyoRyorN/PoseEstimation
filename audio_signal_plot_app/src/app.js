const waveformCanvas = document.querySelector('#waveformCanvas');
const spectrumCanvas = document.querySelector('#spectrumCanvas');
const startButton = document.querySelector('#startButton');
const pauseButton = document.querySelector('#pauseButton');
const stopButton = document.querySelector('#stopButton');
const pauseIcon = document.querySelector('#pauseIcon');
const gainSlider = document.querySelector('#gainSlider');
const fftSizeSelect = document.querySelector('#fftSizeSelect');
const statusText = document.querySelector('#statusText');
const rmsValue = document.querySelector('#rmsValue');
const peakValue = document.querySelector('#peakValue');
const rmsBar = document.querySelector('#rmsBar');
const peakBar = document.querySelector('#peakBar');
const sampleRateValue = document.querySelector('#sampleRateValue');
const windowValue = document.querySelector('#windowValue');
const dominantFrequency = document.querySelector('#dominantFrequency');

const WAVE_COLOR = '#55e0b7';
const WAVE_GLOW = 'rgba(85, 224, 183, 0.16)';
const GRID_COLOR = 'rgba(255, 255, 255, 0.09)';
const MIDLINE_COLOR = 'rgba(255, 255, 255, 0.24)';
const SPECTRUM_LOW = '#6db8ff';
const SPECTRUM_HIGH = '#f0c75d';

let audioContext = null;
let analyser = null;
let sourceNode = null;
let mediaStream = null;
let animationId = 0;
let timeData = new Float32Array(0);
let frequencyData = new Uint8Array(0);
let isRunning = false;
let isPaused = false;

startButton.addEventListener('click', startCapture);
pauseButton.addEventListener('click', togglePause);
stopButton.addEventListener('click', stopCapture);
fftSizeSelect.addEventListener('change', configureAnalyser);
gainSlider.addEventListener('input', () => {
  gainSlider.setAttribute('aria-valuetext', `${gainSlider.value}x`);
});

window.addEventListener('resize', () => {
  resizeCanvas(waveformCanvas);
  resizeCanvas(spectrumCanvas);
  drawIdleState();
});

window.addEventListener('beforeunload', () => {
  stopCapture();
});

drawIdleState();
updateControlState();

async function startCapture() {
  if (!window.isSecureContext) {
    statusText.textContent = 'スマホのマイク利用はHTTPSが必要です';
    return;
  }
  if (!navigator.mediaDevices?.getUserMedia) {
    statusText.textContent = 'このブラウザではマイク入力を使えません';
    return;
  }

  startButton.disabled = true;
  statusText.textContent = 'マイク接続中';

  try {
    mediaStream = await requestMicrophone();
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioContextClass) {
      throw new Error('AudioContext is not available');
    }

    audioContext = new AudioContextClass();
    analyser = audioContext.createAnalyser();
    sourceNode = audioContext.createMediaStreamSource(mediaStream);
    sourceNode.connect(analyser);
    configureAnalyser();

    if (audioContext.state === 'suspended') {
      await audioContext.resume();
    }

    isRunning = true;
    isPaused = false;
    statusText.textContent = '入力中';
    sampleRateValue.textContent = `${audioContext.sampleRate.toLocaleString()} Hz`;
    updateControlState();
    render();
  } catch (error) {
    console.error(error);
    await stopCapture('マイクの開始に失敗しました');
  }
}

async function requestMicrophone() {
  const preciseAudio = {
    audio: {
      channelCount: { ideal: 1 },
      echoCancellation: { ideal: false },
      noiseSuppression: { ideal: false },
      autoGainControl: { ideal: false },
    },
  };

  try {
    return await navigator.mediaDevices.getUserMedia(preciseAudio);
  } catch (error) {
    console.warn('Falling back to default microphone constraints', error);
    return navigator.mediaDevices.getUserMedia({ audio: true });
  }
}

function configureAnalyser() {
  if (!analyser) {
    return;
  }

  const fftSize = Number(fftSizeSelect.value);
  analyser.fftSize = fftSize;
  analyser.minDecibels = -96;
  analyser.maxDecibels = -12;
  analyser.smoothingTimeConstant = 0.12;
  timeData = new Float32Array(analyser.fftSize);
  frequencyData = new Uint8Array(analyser.frequencyBinCount);

  const sampleRate = audioContext?.sampleRate ?? 48000;
  const windowMs = (analyser.fftSize / sampleRate) * 1000;
  windowValue.textContent = `${windowMs.toFixed(1)} ms`;
}

function render() {
  animationId = requestAnimationFrame(render);
  if (!isRunning || isPaused || !analyser) {
    return;
  }

  analyser.getFloatTimeDomainData(timeData);
  analyser.getByteFrequencyData(frequencyData);
  const metrics = getSignalMetrics(timeData);
  const frequency = getDominantFrequency(frequencyData);

  updateMeters(metrics);
  drawWaveform(timeData);
  drawSpectrum(frequencyData, frequency);
}

function getSignalMetrics(samples) {
  let sumSquares = 0;
  let peak = 0;

  for (const sample of samples) {
    const absolute = Math.abs(sample);
    sumSquares += sample * sample;
    if (absolute > peak) {
      peak = absolute;
    }
  }

  const rms = Math.sqrt(sumSquares / samples.length);
  const rmsDb = rms > 0 ? 20 * Math.log10(rms) : -Infinity;
  return { rms, rmsDb, peak };
}

function getDominantFrequency(bins) {
  if (!audioContext || !analyser) {
    return 0;
  }

  const nyquist = audioContext.sampleRate / 2;
  const minIndex = Math.max(1, Math.floor((30 / nyquist) * bins.length));
  const maxIndex = Math.min(bins.length - 1, Math.ceil((8000 / nyquist) * bins.length));
  let loudestIndex = minIndex;
  let loudestValue = 0;

  for (let index = minIndex; index <= maxIndex; index += 1) {
    if (bins[index] > loudestValue) {
      loudestValue = bins[index];
      loudestIndex = index;
    }
  }

  return loudestValue > 8 ? (loudestIndex * nyquist) / bins.length : 0;
}

function updateMeters({ rms, rmsDb, peak }) {
  const rmsPercent = clamp((rms / 0.35) * 100, 0, 100);
  const peakPercent = clamp(peak * 100, 0, 100);
  rmsBar.style.width = `${rmsPercent}%`;
  peakBar.style.width = `${peakPercent}%`;
  rmsValue.textContent = Number.isFinite(rmsDb) ? `${rmsDb.toFixed(1)} dB` : '-∞ dB';
  peakValue.textContent = peak.toFixed(3);
}

function drawWaveform(samples) {
  const { ctx, width, height } = prepareCanvas(waveformCanvas);
  const gain = Number(gainSlider.value);
  const midY = height / 2;

  drawGrid(ctx, width, height, 8, 5);

  ctx.save();
  ctx.strokeStyle = MIDLINE_COLOR;
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(0, midY);
  ctx.lineTo(width, midY);
  ctx.stroke();

  ctx.lineWidth = Math.max(2, width / 520);
  ctx.lineJoin = 'round';
  ctx.lineCap = 'round';
  ctx.shadowColor = WAVE_GLOW;
  ctx.shadowBlur = 16;
  ctx.strokeStyle = WAVE_COLOR;
  ctx.beginPath();

  for (let index = 0; index < samples.length; index += 1) {
    const x = (index / (samples.length - 1)) * width;
    const y = midY - samples[index] * gain * midY * 0.9;
    if (index === 0) {
      ctx.moveTo(x, y);
    } else {
      ctx.lineTo(x, y);
    }
  }

  ctx.stroke();
  ctx.restore();
}

function drawSpectrum(bins, frequency) {
  const { ctx, width, height } = prepareCanvas(spectrumCanvas);
  const nyquist = (audioContext?.sampleRate ?? 48000) / 2;
  const maxFrequency = Math.min(10000, nyquist);
  const maxIndex = Math.floor((maxFrequency / nyquist) * bins.length);
  const barCount = Math.min(maxIndex, Math.max(48, Math.floor(width / 5)));
  const barWidth = width / barCount;

  drawGrid(ctx, width, height, 10, 4);

  for (let bar = 0; bar < barCount; bar += 1) {
    const start = Math.floor((bar / barCount) * maxIndex);
    const end = Math.max(start + 1, Math.floor(((bar + 1) / barCount) * maxIndex));
    let value = 0;
    for (let index = start; index < end; index += 1) {
      value = Math.max(value, bins[index]);
    }

    const normalized = value / 255;
    const barHeight = Math.max(1, normalized * normalized * height * 0.95);
    const x = bar * barWidth;
    const y = height - barHeight;
    ctx.fillStyle = blendColor(SPECTRUM_LOW, SPECTRUM_HIGH, normalized);
    ctx.fillRect(x, y, Math.max(1, barWidth - 1), barHeight);
  }

  if (frequency > 0) {
    const x = clamp((frequency / maxFrequency) * width, 0, width);
    ctx.save();
    ctx.strokeStyle = '#ff7c70';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, height);
    ctx.stroke();
    ctx.restore();
    dominantFrequency.textContent = `${Math.round(frequency).toLocaleString()} Hz`;
  } else {
    dominantFrequency.textContent = '-- Hz';
  }
}

function drawGrid(ctx, width, height, columns, rows) {
  ctx.clearRect(0, 0, width, height);
  ctx.save();
  ctx.strokeStyle = GRID_COLOR;
  ctx.lineWidth = 1;

  for (let column = 1; column < columns; column += 1) {
    const x = (column / columns) * width;
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, height);
    ctx.stroke();
  }

  for (let row = 1; row < rows; row += 1) {
    const y = (row / rows) * height;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(width, y);
    ctx.stroke();
  }

  ctx.restore();
}

function drawIdleState() {
  resizeCanvas(waveformCanvas);
  resizeCanvas(spectrumCanvas);
  const waveform = prepareCanvas(waveformCanvas);
  const spectrum = prepareCanvas(spectrumCanvas);
  drawGrid(waveform.ctx, waveform.width, waveform.height, 8, 5);
  drawGrid(spectrum.ctx, spectrum.width, spectrum.height, 10, 4);
}

function prepareCanvas(canvas) {
  resizeCanvas(canvas);
  return {
    ctx: canvas.getContext('2d'),
    width: canvas.width,
    height: canvas.height,
  };
}

function resizeCanvas(canvas) {
  const rect = canvas.getBoundingClientRect();
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const width = Math.max(1, Math.floor(rect.width * dpr));
  const height = Math.max(1, Math.floor(rect.height * dpr));

  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
}

async function stopCapture(nextStatus = 'マイク待機中') {
  cancelAnimationFrame(animationId);
  animationId = 0;
  isRunning = false;
  isPaused = false;

  if (sourceNode) {
    sourceNode.disconnect();
    sourceNode = null;
  }

  if (mediaStream) {
    for (const track of mediaStream.getTracks()) {
      track.stop();
    }
    mediaStream = null;
  }

  if (audioContext && audioContext.state !== 'closed') {
    await audioContext.close();
  }

  audioContext = null;
  analyser = null;
  timeData = new Float32Array(0);
  frequencyData = new Uint8Array(0);

  statusText.textContent = nextStatus;
  sampleRateValue.textContent = '-- Hz';
  windowValue.textContent = '-- ms';
  dominantFrequency.textContent = '-- Hz';
  updateMeters({ rms: 0, rmsDb: -Infinity, peak: 0 });
  updateControlState();
  drawIdleState();
}

function togglePause() {
  if (!isRunning) {
    return;
  }

  isPaused = !isPaused;
  statusText.textContent = isPaused ? '一時停止中' : '入力中';
  updateControlState();
}

function updateControlState() {
  startButton.disabled = isRunning;
  startButton.classList.toggle('active', isRunning);
  pauseButton.disabled = !isRunning;
  stopButton.disabled = !isRunning;
  fftSizeSelect.disabled = !isRunning;
  pauseIcon.textContent = isPaused ? '▶' : 'Ⅱ';
  pauseButton.title = isPaused ? '再開' : '一時停止';
  pauseButton.setAttribute('aria-label', pauseButton.title);
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function blendColor(fromHex, toHex, amount) {
  const from = parseHexColor(fromHex);
  const to = parseHexColor(toHex);
  const ratio = clamp(amount, 0, 1);
  const red = Math.round(from.red + (to.red - from.red) * ratio);
  const green = Math.round(from.green + (to.green - from.green) * ratio);
  const blue = Math.round(from.blue + (to.blue - from.blue) * ratio);
  return `rgb(${red}, ${green}, ${blue})`;
}

function parseHexColor(hex) {
  return {
    red: Number.parseInt(hex.slice(1, 3), 16),
    green: Number.parseInt(hex.slice(3, 5), 16),
    blue: Number.parseInt(hex.slice(5, 7), 16),
  };
}
