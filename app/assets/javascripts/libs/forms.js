import $ from 'jquery';

export function addCSRFField() {
  const $form = $(this);
  const method = $form.attr('method').toUpperCase();
  const token = $('meta[name=csrf-token]').attr('content');

  // add the CSRF token as a hidden input to the form
  if (method && method !== 'GET') {
    $form.prepend($('<input>', { name: '_csrf', type: 'hidden', value: token }));
  }
}
