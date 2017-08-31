(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('jQuery'));
  } else {
    root.tags = factory(root.jQuery);
  }
}(this, function ($) {

  // IMPORTANT: views MUST supply divs with the below ids for this module to function
  var DIVS = {
    container: '#tags-container',
    control: '#tags-controls',
    edit: '#tags-edit-button'
  };
  
  var t = {}; // object for public exports
  var STATE = {}; // store

  // STORE FUNCTIONS

  // type TagsRepository = { [all: string]: TagsById, [current: string]: Array<string>, divs: Divs}
  // type TagsById = { [id: string]: Tag }
  // type DivsById = { [id: string]: string }
  // type Tag = type { name: string, description: string, id: number }
  
  /**
   * Initalization of widget 
   * @param {TagsRepository} tags
   * @param {DivsById} divs
   * @param {Boolean|Undefined} alwaysEdit
   * @return {Object}
   */
  t.init = function(tags, endpoint, alwaysEdit){
    STATE = {
      tags: {
        byId: tags.all,
        current: tags.current.map(String)
      },
      cache: {
        html: $(DIVS.container).html(),
        tags: tags.current.map(String)
      },
      endpoint: endpoint,
      alwaysEdit: Boolean(alwaysEdit)
    };

    // render immediately in perpetual edit mode, otherwise wait for click
    STATE.alwaysEdit ? renderAndHideEdit() : handleEditClick();
    
    return STATE;
  };

  // getter
  t.get = function() {
    return STATE;
  };

  // str -> ?string
  t.getId = function(name){
    return Object.keys(STATE.tags.byId).filter(function(k){
      return STATE.tags.byId[k].name === name;
    })[0];
  };

  t.available = function(){
    return Object.keys(STATE.tags.byId).filter(function(id){
      return !STATE.tags.current.includes(id);
    });
  };

  // mutate store
  t.update = function(action, id){
    t[action](id);
    t.render();
  };

  // input: str
  t.add = function(id) {
    STATE.tags.current = STATE.tags.current.concat(String(id));
  };
  
  t.remove = function(idToRemove){
    STATE.tags.current = STATE.tags.current.filter(function(id){
      return id !== String(idToRemove);
    });
  };

  // RENDER FUNCTIONS

  function handleEditClick(){
    $(DIVS.edit).click(renderAndHideEdit);
  }

  function renderAndHideEdit() {
    $(DIVS.edit).hide();
    renderControls();
    t.render();
  }

  function renderControls(){
    $(DIVS.control)
      .append(saveButton())
      .append(cancelButton());
  }

  function saveButton(){
    return $('<button>', {
      id: 'tags-save-button',
      text: 'save',
      click: function(e){
	e.preventDefault();
        $.post(STATE.endpoint, {tags: { ids: STATE.tags.current  }})
          .done(function(){ window.location.reload(true); });
      }
    });
  }

  function cancelButton(){
    return $('<button>', {
      id: 'tags-cancel-button',
      text: 'cancel',
      click: function(e){
	e.preventDefault();
	STATE.tags.current = STATE.cache.tags; // restore state
        STATE.alwaysEdit
	  ? t.render()    // in perpetual edit mode we only need to re-render
	  : restoreDom(); // normbyIdy, we must restore the pre-edit-mode view
      }
    });    
  }

  function restoreDom(){
    $(DIVS.container).html(STATE.cache.html);
    $('#tags-save-button').remove();
    $('#tags-cancel-button').remove();
    $(DIVS.edit).show();
  }
  
  // update done
  t.render = function(){
    $(DIVS.container)
      .empty()
      .append(tagList())
      .append(select());
    
    $('#tags-select').selectpicker(); // possible to move this into select()?
  };

  
  // select field
  function select(){
    return $('<select>', {
      class: 'selectpicker',
      id: 'tags-select',
      title: 'Pick a tag...',
      'data-live-search': true,
      
      on: {
        'changed.bs.select': function(e) {
          updateIfValid($(this).val());
        }
      }
    })
      .append(selectOptions());
  }

  function selectOptions(){
    return t.available().map(function(tagId){
      return $('<option>', {
        class: 'tags-select-option',
        text: STATE.tags.byId[tagId].name
      });
    });
  };
  
  function updateIfValid(tagInput){
    var id = t.getId(tagInput);
    if (isValid(id)) t.update('add', id);
  }

  function isValid(id){
    return Boolean(id) &&
      !STATE.tags.current.includes(id);
  }
  
  function tagList(){
    return $('<ul>', {id: 'tags-edit-list'})
      .append(STATE.tags.current.map(tagButton));
  }
  
  function tagButton(id){
    return $('<li>', {
      class: 'tag',
      text: STATE.tags.byId[id].name
    }).append(removeButton(id));
  }

  function removeButton(id) {
    return $('<span>', {
      class: 'tag-remove-button',
      click: function(){
	t.update('remove', id);
      }
    });
  }

  return t;
  
}));
 
