/* ==================== CONFIGURATION ==================== */
const STATIC_LINK = window.location.origin;
const FALLBACK_THUMB = "/static/default.png";

/* Media Type Constants */
const MEDIA_TYPES = {
  SERIES: 0,
  MOVIES: 1,
  MUSIC: 2
};

/* Format Support */
const BROWSER_VIDEO = ["mp4", "webm", "ogg"];
const BROWSER_AUDIO = ["mp3", "wav", "ogg", "aac", "m4a"];

/* ==================== STATE MANAGEMENT ==================== */
let libraryData = null;
let currentFilter = 'all';
let searchQuery = '';

/* ==================== HELPER FUNCTIONS ==================== */
function getExt(name) {
  return name.split(".").pop().toLowerCase();
}

function isBrowserPlayable(name) {
  const ext = getExt(name);
  return BROWSER_VIDEO.includes(ext) || BROWSER_AUDIO.includes(ext);
}

function buildThumb(path) {
  if (!path) return `${STATIC_LINK}${FALLBACK_THUMB}`;
  const parts = path.split("/");
  const fileName = encodeURIComponent(parts.pop());
  const dir = parts.join("/");
  return `${STATIC_LINK}${dir}/${fileName}`;
}

function linkGenerator(name, type, episode = "") {
  if (type === MEDIA_TYPES.SERIES) {
    return `${STATIC_LINK}/series/${encodeURIComponent(name)}/${encodeURIComponent(episode)}`;
  }
  if (type === MEDIA_TYPES.MOVIES) {
    return `${STATIC_LINK}/movies/${encodeURIComponent(name)}`;
  }
  return `${STATIC_LINK}/musics/${encodeURIComponent(name)}`;
}

function matchesSearch(text) {
  if (!searchQuery) return true;
  return text.toLowerCase().includes(searchQuery.toLowerCase());
}

/* ==================== MODAL FUNCTIONS ==================== */
const modal = document.getElementById("media-modal");
const modalTitle = document.getElementById("modal-title");
const modalActions = document.getElementById("modal-actions");

function closeModal() {
  modal.classList.add("hidden");
  document.body.style.overflow = '';
}

function openMediaModal(name, streamUrl) {
  modalTitle.textContent = name;
  modalActions.innerHTML = "";

  const playable = isBrowserPlayable(name);

  // Play in Browser button
  if (playable) {
    const playBrowser = document.createElement("a");
    playBrowser.textContent = "▶ Play in Browser";
    playBrowser.href = streamUrl;
    playBrowser.target = "_blank";
    modalActions.appendChild(playBrowser);
  }

  // Play in External Player button
  const playExternal = document.createElement("a");
  playExternal.textContent = "🎬 Open in External Player";
  playExternal.href = streamUrl;
  playExternal.target = "_blank";
  modalActions.appendChild(playExternal);

  // Help text for VLC
  const help = document.createElement("div");
  help.className = "help-text";
  help.innerHTML = `
    <p><b>VLC Users:</b> Media → Open Network Stream</p>
    <code>${streamUrl}</code>
  `;
  modalActions.appendChild(help);

  // Download button
  const download = document.createElement("a");
  download.textContent = "⬇ Download";
  download.href = streamUrl;
  download.download = "";
  modalActions.appendChild(download);

  modal.classList.remove("hidden");
  document.body.style.overflow = 'hidden';
}

// Close modal on click outside
modal.addEventListener('click', (e) => {
  if (e.target === modal) {
    closeModal();
  }
});

// Close button
document.querySelector('.close-btn').addEventListener('click', closeModal);

// Close on Escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !modal.classList.contains('hidden')) {
    closeModal();
  }
});

/* ==================== CARD CREATION ==================== */
function createCard(item, type, seriesName = "") {
  const card = document.createElement("a");
  card.className = "card";
  card.style.backgroundImage = `url(${buildThumb(item.thumbnail)})`;
  card.setAttribute('data-name', item.name.toLowerCase());

  const streamUrl = type === MEDIA_TYPES.SERIES 
    ? linkGenerator(seriesName, type, item.name)
    : linkGenerator(item.name, type);

  card.onclick = (e) => {
    e.preventDefault();
    openMediaModal(item.name, streamUrl);
  };

  const heading = document.createElement(type === MEDIA_TYPES.SERIES ? "h4" : "h3");
  heading.textContent = item.name;
  card.appendChild(heading);

  return card;
}

/* ==================== RENDER FUNCTIONS ==================== */
function renderMovies(container, movies) {
  if (!movies || movies.length === 0) return;

  const moviesTitle = document.createElement("h2");
  moviesTitle.id = "movies-section";
  moviesTitle.innerHTML = `Movies <span class="section-badge">${movies.length}</span>`;

  const moviesSection = document.createElement("div");
  moviesSection.className = "section";
  moviesSection.setAttribute('data-section', 'movies');

  const filteredMovies = movies.filter(movie => matchesSearch(movie.name));

  if (filteredMovies.length === 0) {
    moviesSection.classList.add('empty-state');
    moviesSection.textContent = 'No movies found';
  } else {
    filteredMovies.forEach(movie => {
      moviesSection.appendChild(createCard(movie, MEDIA_TYPES.MOVIES));
    });
  }

  container.appendChild(moviesTitle);
  container.appendChild(moviesSection);
}

function renderSeries(container, series) {
  if (!series || Object.keys(series).length === 0) return;

  const seriesTitle = document.createElement("h2");
  seriesTitle.id = "series-section";
  
  const totalEpisodes = Object.values(series).reduce((sum, eps) => sum + eps.length, 0);
  seriesTitle.innerHTML = `Series <span class="section-badge">${totalEpisodes} episodes</span>`;

  const seriesSection = document.createElement("div");
  seriesSection.className = "section";
  seriesSection.setAttribute('data-section', 'series');

  let hasVisibleContent = false;

  for (const seriesName in series) {
    const episodes = series[seriesName];
    const filteredEpisodes = episodes.filter(ep => 
      matchesSearch(ep.name) || matchesSearch(seriesName)
    );

    if (filteredEpisodes.length > 0) {
      hasVisibleContent = true;

      const title = document.createElement("div");
      title.className = "series-title";
      title.textContent = seriesName;
      seriesSection.appendChild(title);

      filteredEpisodes.forEach(ep => {
        seriesSection.appendChild(createCard(ep, MEDIA_TYPES.SERIES, seriesName));
      });
    }
  }

  if (!hasVisibleContent) {
    seriesSection.classList.add('empty-state');
    seriesSection.textContent = 'No series found';
  }

  container.appendChild(seriesTitle);
  container.appendChild(seriesSection);
}

function renderMusic(container, music) {
  if (!music || music.length === 0) return;

  const musicTitle = document.createElement("h2");
  musicTitle.id = "music-section";
  musicTitle.innerHTML = `Music <span class="section-badge">${music.length}</span>`;

  const musicSection = document.createElement("div");
  musicSection.className = "section";
  musicSection.setAttribute('data-section', 'music');

  const filteredMusic = music.filter(song => matchesSearch(song.name));

  if (filteredMusic.length === 0) {
    musicSection.classList.add('empty-state');
    musicSection.textContent = 'No music found';
  } else {
    filteredMusic.forEach(song => {
      musicSection.appendChild(createCard(song, MEDIA_TYPES.MUSIC));
    });
  }

  container.appendChild(musicTitle);
  container.appendChild(musicSection);
}

function renderContent() {
  const container = document.getElementById("content-container");
  container.innerHTML = "";

  if (!libraryData) return;

  // Render based on active filter
  if (currentFilter === 'all' || currentFilter === 'movies') {
    renderMovies(container, libraryData.movies);
  }
  
  if (currentFilter === 'all' || currentFilter === 'series') {
    renderSeries(container, libraryData.series);
  }
  
  if (currentFilter === 'all' || currentFilter === 'music') {
    renderMusic(container, libraryData.music);
  }

  // Show empty state if no content
  if (container.children.length === 0) {
    container.innerHTML = '<div class="section empty-state">No media found matching your search</div>';
  }
}

/* ==================== SEARCH & FILTER ==================== */
const searchInput = document.getElementById("search-input");
const filterButtons = document.querySelectorAll(".filter-btn");

searchInput.addEventListener("input", (e) => {
  searchQuery = e.target.value.trim();
  renderContent();
});

filterButtons.forEach(btn => {
  btn.addEventListener("click", () => {
    filterButtons.forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    currentFilter = btn.dataset.filter;
    renderContent();
  });
});

/* ==================== LOAD LIBRARY ==================== */
const loadingState = document.getElementById("loading-state");

function showError(message) {
  loadingState.innerHTML = `
    <div style="text-align: center; color: #ef4444;">
      <p style="font-size: 2rem; margin-bottom: 10px;">⚠️</p>
      <p style="font-size: 1.2rem;">${message}</p>
      <button onclick="location.reload()" style="margin-top: 20px; padding: 10px 20px; background: #38bdf8; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600;">Retry</button>
    </div>
  `;
}

fetch(`${STATIC_LINK}/library`)
  .then(res => {
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
    return res.json();
  })
  .then(data => {
    libraryData = data;
    loadingState.style.display = 'none';
    renderContent();
  })
  .catch(err => {
    console.error("Failed to load library:", err);
    showError("Failed to load library. Please check your connection and try again.");
  });