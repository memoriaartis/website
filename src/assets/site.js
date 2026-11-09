document.documentElement.classList.add('js');
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
