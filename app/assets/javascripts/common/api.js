(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('jQuery'), require('../common/utility'));
  } else {
    root.api = factory(root.jQuery, root.utility);
  }
}(this, function ($, util) {

  // API
  var self = {};

  self.searchEntity = function(query){
    return get('/search/entity', { num: 10, no_summary: true, q: query })
      .then(format)
      .catch(handleError);

    function format(results){
      return results.reduce(function(acc, result) {
        var _result = Object.assign({}, result, {
          primary_ext: result.primary_ext || result.primary_type,
          blurb:       result.blurb || result.description,
          id:          String(result.id)
        });
        delete _result.primary_type;
        delete _result.description;
        return acc.concat([_result]);
      },[]);
    }

    function handleError(err){
      console.error('API request error: ', err);
      return [];
    }
  };

  // [EntityWithoutId] -> Promise[[Entity]]
  self.createEntities = function(entities){
    return post('/entities/bulk', formatReq(entities))
      .then(formatResp);

    function formatReq(entities){
      return {
        data: entities.map(function(entity){
          return {
            type: "entities",
            attributes: entity
          };
        })
      };
    };

    function formatResp(resp){
      return resp.data.map(function(datum){
        return Object.assign(
          datum.attributes,
          { id: String(datum.attributes.id)}
        );
      });
    }
  };

  // Integer, [Integer] -> Promise[[ListEntity]]
  self.addEntitiesToList = function(listId, entityIds, reference){
    return post('/lists/'+listId+'/entities/bulk', formatReq(entityIds))
      .then(formatResp);

    function formatReq(entityIds){

      return {
        data: entityIds.map(function(id){
          return { type: 'entities', id: id };
        }).concat({
          type: 'references',
          attributes: reference
        })
      };
    };

    function formatResp(resp){
      return resp.data.map(function(datum){
        return util.stringifyValues(datum.attributes);
      });
    }
  };

  // helpers

  function get(url, queryParams){
    return fetch(url + qs(queryParams), {
      headers:      headers(),
      method:      'get',
      credentials: 'include' // use auth tokens stored in session cookies
    }).then(jsonify);
  }

  function post(url, payload){
    return fetch(url, {
      headers:     headers(),
      method:      'post',
      credentials: 'include', // use auth tokens stored in session cookies
      body:        JSON.stringify(payload)
    }).then(jsonify);
  };

  function headers(){
    return {
      'Accept':       'application/json, text/plain, */*',
      'Content-Type': 'application/json',
       // TODO: retrieve this w/o JQuery
      'X-CSRF-Token': $("meta[name='csrf-token']").attr("content") || ""
    };
  }

  function qs(queryParams){
    return '?' + $.param(queryParams);
  }

  // Response -> Promise[Error|JSON]
  function jsonify(response){
    return response
      .json()
      .then(function(json){
        return json.errors ?
          Promise.reject(json.errors[0].title) :
          Promise.resolve(json);
      });
  }
  
  return self;
}));
