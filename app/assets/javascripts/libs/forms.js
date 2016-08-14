import $ from 'jquery';

export function addCSRFField(form) {
  const $form = $(form);
  const method = $form.attr('method').toUpperCase();
  const token = $('meta[name=csrf-token]').attr('content');

  // add the CSRF token as a hidden input to the form
  if (method && method !== 'GET') {
    $form.prepend($('<input>', { name: '_csrf', type: 'hidden', value: token }));
  }
}

export function serializeObject(obj) {
  const $obj = $(obj);
  const o = {};
  const a = $obj.serializeArray();
  $.each(a, () => {
    if (o[$obj.name] !== undefined) {
      if (!o[$obj.name].push) {
        o[$obj.name] = [o[$obj.name]];
      }
      o[$obj.name].push($obj.value || '');
    } else {
      o[$obj.name] = $obj.value || '';
    }
  });
  return o;
}
