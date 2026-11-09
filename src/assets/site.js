document.documentElement.classList.add('js');

// Reproject image-anchored annotations whenever object-fit: cover changes crop.
function initPhotoAnnotations() {
  for (const svg of document.querySelectorAll('[data-photo-annotation]')) {
    const frame = svg.closest('.photo-frame');
    const image = frame?.querySelector('img');
    const line = svg.querySelector('line');
    const label = frame?.querySelector('[data-photo-label]');
    if (!frame || !image || !line || !label) continue;

    const imagePoints = {
      x1: Number(svg.dataset.sourceX1),
      y1: Number(svg.dataset.sourceY1),
      x2: Number(svg.dataset.sourceX2),
      y2: Number(svg.dataset.sourceY2),
      labelX: Number(label.dataset.sourceX),
      labelY: Number(label.dataset.sourceY),
    };

    function metrics() {
      if (!image.naturalWidth || !image.naturalHeight) return null;
      const width = frame.clientWidth;
      const height = frame.clientHeight;
      if (!width || !height) return null;
      const scale = Math.max(width / image.naturalWidth, height / image.naturalHeight);
      const renderedWidth = image.naturalWidth * scale;
      const renderedHeight = image.naturalHeight * scale;
      const positions = getComputedStyle(image).objectPosition.split(/\s+/);
      const percent = (value) => value?.endsWith('%') ? Number.parseFloat(value) / 100 : 0.5;
      return {
        width, height, scale,
        offsetX: (width - renderedWidth) * percent(positions[0]),
        offsetY: (height - renderedHeight) * percent(positions[1]),
      };
    }

    function update() {
      const size = metrics();
      if (!size) return;
      const toFrameX = (value) => (value / 100 * image.naturalWidth * size.scale + size.offsetX) / size.width * 100;
      const toFrameY = (value) => (value / 100 * image.naturalHeight * size.scale + size.offsetY) / size.height * 100;
      line.setAttribute('x1', toFrameX(imagePoints.x1));
      line.setAttribute('y1', toFrameY(imagePoints.y1));
      line.setAttribute('x2', toFrameX(imagePoints.x2));
      line.setAttribute('y2', toFrameY(imagePoints.y2));
      label.style.left = `${toFrameX(imagePoints.labelX)}%`;
      label.style.top = `${toFrameY(imagePoints.labelY)}%`;
    }

    image.addEventListener('load', update);
    if (image.complete) update();
    new ResizeObserver(update).observe(frame);
  }
}
initPhotoAnnotations();

const menu = document.querySelector('[data-menu]');
const toggle = document.querySelector('[data-menu-toggle]');
function setMenu(open) {
  menu.classList.toggle('is-open', open);
  toggle.setAttribute('aria-expanded', String(open));
  toggle.textContent = open ? toggle.dataset.close : toggle.dataset.open;
}
toggle?.addEventListener('click', () => setMenu(toggle.getAttribute('aria-expanded') !== 'true'));
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && toggle?.getAttribute('aria-expanded') === 'true') {
    setMenu(false);
    toggle.focus();
  }
});
const mobile = matchMedia('(max-width: 760px)');
mobile.addEventListener('change', () => setMenu(false));
const subject = document.querySelector('[name="subject"]');
const requested = new URLSearchParams(location.search).get('sujet');
if (subject && ['savoir-faire', 'partenariat', 'soutien'].includes(requested)) subject.value = requested;
const form = document.querySelector('form');
if (form) {
  for (const field of form.querySelectorAll('input, select, textarea')) {
    const error = document.createElement('p');
    error.id = `${field.id}-error`;
    error.className = 'error';
    error.setAttribute('aria-live', 'polite');
    field.after(error);
    const description = field.getAttribute('aria-describedby') || '';
    field.setAttribute('aria-describedby', `${description} ${error.id}`.trim());
    function validate() {
      let message = '';
      if (field.validity.valueMissing) message = field === subject ? form.dataset.subjectError : form.dataset.required;
      else if (field.validity.typeMismatch) message = form.dataset.emailError;
      else if (field.validity.tooLong) message = form.dataset.lengthError;
      error.textContent = message;
      field.setAttribute('aria-invalid', String(Boolean(message)));
    }
    field.addEventListener('blur', validate);
    field.addEventListener('input', () => {
      if (field.getAttribute('aria-invalid') === 'true') validate();
    });
  }
}
// This preview has no delivery endpoint. The form stays disabled until a
// server-side integration exists; a confirmed email enables the email-only build.
