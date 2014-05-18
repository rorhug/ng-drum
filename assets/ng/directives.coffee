drum.directive "focusMe", ($timeout, $parse) ->
  link: (scope, element, attrs) ->
    model = $parse(attrs.focusMe)
    scope.$watch model, (value) ->
      if value is true
        $timeout ->
          element[0].focus()
    
    element.bind "blur", ->
      scope.$apply model.assign(scope, false)

drum.directive "selectAllOnClick", ($timeout) ->
  link: (scope, element, attrs) ->
    $timeout ->
      element[0].focus()
      element[0].select()