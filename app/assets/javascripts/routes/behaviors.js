import $ from 'jquery';

$.extend($.expr[':'], {
  containsi: (elem, i, match) =>
    (elem.textContent || elem.innerText || '').toLowerCase()
    .indexOf((match[3] || '').toLowerCase()) >= 0
});

const behaviors = {
  init: () => {
    $(document).on('input', 'input.search', behaviors.filterBehaviors);
  },

  filterBehaviors: (ev) => {
    const term = $(ev.currentTarget).val();
    $('li.behavior').hide();
    $(`li.behavior:containsi(${term})`).show();
  }
};

export default behaviors;
