import {
  FilesetResolver,
  PoseLandmarker,
} from 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.35/vision_bundle.mjs';

const WASM_ROOT =
  'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.35/wasm';
const MODEL_URL =
  'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task';

const LANDMARK_NAMES = [
  'nose',
  'leftEyeInner',
  'leftEye',
  'leftEyeOuter',
  'rightEyeInner',
  'rightEye',
  'rightEyeOuter',
  'leftEar',
  'rightEar',
  'mouthLeft',
  'mouthRight',
  'leftShoulder',
  'rightShoulder',
  'leftElbow',
  'rightElbow',
  'leftWrist',
  'rightWrist',
  'leftPinky',
  'rightPinky',
  'leftIndex',
  'rightIndex',
  'leftThumb',
  'rightThumb',
  'leftHip',
  'rightHip',
  'leftKnee',
  'rightKnee',
  'leftAnkle',
  'rightAnkle',
  'leftHeel',
  'rightHeel',
  'leftFootIndex',
  'rightFootIndex',
];

const CONNECTIONS = [
  ['leftShoulder', 'leftElbow'],
  ['leftElbow', 'leftWrist'],
  ['rightShoulder', 'rightElbow'],
  ['rightElbow', 'rightWrist'],
  ['leftShoulder', 'rightShoulder'],
  ['leftShoulder', 'leftHip'],
  ['rightShoulder', 'rightHip'],
  ['leftHip', 'rightHip'],
  ['leftHip', 'leftKnee'],
  ['leftKnee', 'leftAnkle'],
  ['rightHip', 'rightKnee'],
  ['rightKnee', 'rightAnkle'],
];

const CSV_HEADER = [
  'session_id',
  'timestamp_ms',
  'frame_index',
  'joint',
  'x',
  'y',
  'z',
  'confidence',
  'image_width',
  'image_height',
  'camera_lens',
  'rotation_deg',
];

const video = document.querySelector('#cameraVideo');
const canvas = document.querySelector('#overlayCanvas');
const ctx = canvas.getContext('2d');
const statusText = document.querySelector('#statusText');
const poseFps = document.querySelector('#poseFps');
const frameCount = document.querySelector('#frameCount');
const detectionRate = document.querySelector('#detectionRate');
const recordButton = document.querySelector('#recordButton');
const recordIcon = document.querySelector('#recordIcon');
const recordLabel = document.querySelector('#recordLabel');
const switchButton = document.querySelector('#switchButton');
const downloadButton = document.querySelector('#downloadButton');
const elapsedTime = document.querySelector('#elapsedTime');

let poseLandmarker;
let mediaStream;
let facingMode = 'environment';
let isRunning = false;
let isProcessing = false;
let lastVideoTime = -1;
let cameraFrames = 0;
let processedFrames = 0;
let detectedFrames = 0;
let fpsWindowStartedAt = performance.now();
let fpsWindowFrames = 0;
let recording = null;
let lastRecordingFiles = null;
let animationId = 0;

recordButton.addEventListener('click', () => {
  if (recording) {
    stopRecording();
    return;
  }
  startRecording();
});

switchButton.addEventListener('click', async () => {
  facingMode = facingMode === 'environment' ? 'user' : 'environment';
  await startCamera();
});

downloadButton.addEventListener('click', () => {
  if (!lastRecordingFiles) return;
  downloadBlob(lastRecordingFiles.csvBlob, lastRecordingFiles.csvName);
  downloadBlob(lastRecordingFiles.jsonBlob, lastRecordingFiles.jsonName);
});

await boot();

async function boot() {
  try {
    const vision = await FilesetResolver.forVisionTasks(WASM_ROOT);
    poseLandmarker = await PoseLandmarker.createFromOptions(vision, {
      baseOptions: {
        modelAssetPath: MODEL_URL,
        delegate: 'GPU',
      },
      runningMode: 'VIDEO',
      numPoses: 1,
      minPoseDetectionConfidence: 0.5,
      minPosePresenceConfidence: 0.5,
      minTrackingConfidence: 0.5,
    });

    statusText.textContent = 'Starting camera';
    await startCamera();
    recordButton.disabled = false;
    switchButton.disabled = false;
    isRunning = true;
    renderLoop();
  } catch (error) {
    console.error(error);
    statusText.textContent = 'Camera or model initialization failed';
  }
}

async function startCamera() {
  stopCamera();
  video.classList.toggle('mirrored', facingMode === 'user');

  mediaStream = await navigator.mediaDevices.getUserMedia({
    audio: false,
    video: {
      facingMode: { ideal: facingMode },
      width: { ideal: 1280 },
      height: { ideal: 720 },
    },
  });

  video.srcObject = mediaStream;
  await video.play();
  resizeCanvasToVideo();
  statusText.textContent = 'Camera ready';
}

function stopCamera() {
  if (!mediaStream) return;
  for (const track of mediaStream.getTracks()) {
    track.stop();
  }
  mediaStream = null;
}

function renderLoop() {
  animationId = requestAnimationFrame(renderLoop);
  if (!isRunning || isProcessing || video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) {
    return;
  }
  if (video.currentTime === lastVideoTime) {
    return;
  }

  cameraFrames += 1;
  frameCount.textContent = String(cameraFrames);
  lastVideoTime = video.currentTime;
  isProcessing = true;

  try {
    resizeCanvasToVideo();
    const timestampMs = Date.now();
    const result = poseLandmarker.detectForVideo(video, performance.now());
    processedFrames += 1;
    fpsWindowFrames += 1;
    const landmarks = result.landmarks?.[0] ?? [];
    if (landmarks.length > 0) {
      detectedFrames += 1;
    }
    drawLandmarks(landmarks);
    updateStats();
    if (recording && landmarks.length > 0) {
      appendFrameRows(landmarks, timestampMs);
    }
  } finally {
    isProcessing = false;
  }
}

function resizeCanvasToVideo() {
  const width = video.videoWidth || 1280;
  const height = video.videoHeight || 720;
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
}

function drawLandmarks(landmarks) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  if (!landmarks.length) return;

  const byName = new Map();
  landmarks.forEach((landmark, index) => {
    byName.set(LANDMARK_NAMES[index], landmark);
  });

  ctx.save();
  if (facingMode === 'user') {
    ctx.translate(canvas.width, 0);
    ctx.scale(-1, 1);
  }

  ctx.lineWidth = 5;
  ctx.lineCap = 'round';
  ctx.strokeStyle = '#5eead4';
  for (const [fromName, toName] of CONNECTIONS) {
    const from = byName.get(fromName);
    const to = byName.get(toName);
    if (!from || !to || confidenceOf(from) < 0.35 || confidenceOf(to) < 0.35) {
      continue;
    }
    ctx.beginPath();
    ctx.moveTo(from.x * canvas.width, from.y * canvas.height);
    ctx.lineTo(to.x * canvas.width, to.y * canvas.height);
    ctx.stroke();
  }

  for (const landmark of landmarks) {
    ctx.beginPath();
    ctx.fillStyle = confidenceOf(landmark) >= 0.35 ? '#fff7ed' : '#ffb86b';
    ctx.arc(landmark.x * canvas.width, landmark.y * canvas.height, 6, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.restore();
}

function startRecording() {
  const startedAt = new Date();
  recording = {
    sessionId: createSessionId(startedAt),
    startedAt,
    rows: [CSV_HEADER],
    frameIndex: 0,
    detectedPoseFrames: 0,
  };
  recordButton.classList.add('recording');
  recordIcon.setAttribute('aria-hidden', 'true');
  recordLabel.textContent = 'Stop';
  statusText.textContent = 'Recording';
}

function stopRecording() {
  if (!recording) return;
  const endedAt = new Date();
  const csv = rowsToCsv(recording.rows);
  const metadata = {
    session_id: recording.sessionId,
    started_at: recording.startedAt.toISOString(),
    ended_at: endedAt.toISOString(),
    camera_lens: facingMode === 'user' ? 'front' : 'back',
    image_width: video.videoWidth,
    image_height: video.videoHeight,
    pose_model: 'pose_landmarker_lite',
    confidence_threshold: 0.5,
    app_version: '0.1.0-web',
    total_frames: recording.frameIndex,
    detected_pose_frames: recording.detectedPoseFrames,
    saved_rows: Math.max(0, recording.rows.length - 1),
  };

  lastRecordingFiles = {
    csvBlob: new Blob([csv], { type: 'text/csv;charset=utf-8' }),
    jsonBlob: new Blob([JSON.stringify(metadata, null, 2)], {
      type: 'application/json;charset=utf-8',
    }),
    csvName: `pose_${recording.sessionId}.csv`,
    jsonName: `pose_${recording.sessionId}.json`,
  };

  recording = null;
  downloadButton.disabled = false;
  recordButton.classList.remove('recording');
  recordLabel.textContent = 'Start';
  elapsedTime.textContent = '00:00';
  statusText.textContent = 'Saved recording';
}

function appendFrameRows(landmarks, timestampMs) {
  const cameraLens = facingMode === 'user' ? 'front' : 'back';
  const frameIndex = recording.frameIndex;
  recording.frameIndex += 1;
  recording.detectedPoseFrames += 1;

  landmarks.forEach((landmark, index) => {
    recording.rows.push([
      recording.sessionId,
      timestampMs,
      frameIndex,
      LANDMARK_NAMES[index],
      landmark.x * video.videoWidth,
      landmark.y * video.videoHeight,
      landmark.z ?? 0,
      confidenceOf(landmark),
      video.videoWidth,
      video.videoHeight,
      cameraLens,
      0,
    ]);
  });
}

function updateStats() {
  const now = performance.now();
  const elapsed = now - fpsWindowStartedAt;
  if (elapsed >= 700) {
    poseFps.textContent = ((fpsWindowFrames * 1000) / elapsed).toFixed(1);
    fpsWindowFrames = 0;
    fpsWindowStartedAt = now;
  }

  const rate = processedFrames === 0 ? 0 : detectedFrames / processedFrames;
  detectionRate.textContent = `${Math.round(rate * 100)}%`;

  if (recording) {
    const seconds = Math.floor((Date.now() - recording.startedAt.getTime()) / 1000);
    elapsedTime.textContent = formatDuration(seconds);
  }
}

function rowsToCsv(rows) {
  return rows
    .map((row) =>
      row
        .map((value) => {
          const text = String(value ?? '');
          return /[",\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
        })
        .join(','),
    )
    .join('\n');
}

function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

function confidenceOf(landmark) {
  return landmark.visibility ?? landmark.presence ?? 1;
}

function createSessionId(date) {
  const two = (value) => String(value).padStart(2, '0');
  return `${date.getFullYear()}${two(date.getMonth() + 1)}${two(date.getDate())}_${two(
    date.getHours(),
  )}${two(date.getMinutes())}${two(date.getSeconds())}`;
}

function formatDuration(totalSeconds) {
  const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, '0');
  const seconds = String(totalSeconds % 60).padStart(2, '0');
  return `${minutes}:${seconds}`;
}

window.addEventListener('beforeunload', () => {
  cancelAnimationFrame(animationId);
  stopCamera();
});
