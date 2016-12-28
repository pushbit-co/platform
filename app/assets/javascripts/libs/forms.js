import $ from 'jquery';

export function addCSRFField($form) {
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

  $.each(a, (index, item) => {
    if (o[item.name] !== undefined) {
      if (!o[item.name].push) {
        o[item.name] = [o[item.name]];
      }
      o[item.name].push(item.value || '');
    } else {
      o[item.name] = item.value || '';
    }
  });
  return o;
}
