import $ from 'jquery';
import {addCSRFField} from '../libs/forms';

$.extend($.expr[':'], {
  containsi: (elem, i, match) =>
    (elem.textContent || elem.innerText || '').toLowerCase()
    .indexOf((match[3] || '').toLowerCase()) >= 0
});

const behaviors = {
  init: () => {
    behaviors.injectTeams();
    $(document).on('click', 'button.expand', behaviors.expandBehavior);
    $(document).on('input', 'input.search', behaviors.filterBehaviors);
    $(document).on('change', '.content input', behaviors.saveSettings);
    $(document).on('change', '.content select', behaviors.saveSettings);
  },

  filterBehaviors: (ev) => {
    const term = $(ev.currentTarget).val();
    $('li.behavior').hide();
    $(`li.behavior:containsi(${term})`).show();
  },

  injectTeams: () => {
    $.ajax({
      type: 'GET',
      url: `${window.location.href}/teams`,
      success: (data) => {
        // initial value is stored in a hidden field
        const value = $('input[name=setting_team]').val();

        $.each(data.teams, (key, team) => {
          $('select[name=setting_team]')
          .append($('<option></option>')
          .attr('value', team.id)
          .attr('selected', value === team.id.toString() ? true : undefined)
          .text(team.name));
        });
      }
    });
  },

  saveSettings: (ev) => {
    const $form = $(ev.currentTarget).parents('form');
    addCSRFField($form);

    $.ajax({
      type: $form.attr('method'),
      url: $form.attr('action'),
      data: $form.serialize(),
      success: () => {
        //
      }
    });
  },

  expandBehavior: (ev) => {
    ev.preventDefault();

    // open the one we clicked
    $(ev.currentTarget)
    .parents('.behavior')
    .find('.content')
    .fadeToggle();
  }
};

export default behaviors;
