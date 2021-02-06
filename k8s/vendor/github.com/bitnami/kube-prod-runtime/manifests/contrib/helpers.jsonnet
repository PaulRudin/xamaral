// Set of contributed helper functions
// NOTE that these are not end-to-end tested by BKPR CI/CD
//
// See contrib/helpers_usage_test.jsonnet for example usage
{
  trace:: false,
  // Identity function, will run thru std.trace if $.trace is set to true
  _T(str, x):: (
    if $.trace
    then std.trace('%s: %s' % [str, std.toString(x)], x)
    else x
  ),
  // Set at specific path, e.g.
  // setAtPath("x.y.z", 42) -> { x: { y: { z: 42 } } }
  setAtPath(path, value):: (
    local nested_field_from_array(arr) = (
      assert std.length(arr) > 0 : 'array must not be empty';
      if std.length(arr) == 1
      then { [arr[0]]: value }
      else ({ [arr[0]]+: nested_field_from_array(arr[1:]) })
    );
    $._T('setAtPath()', nested_field_from_array(std.split(path, '.')))
  ),
  // Do std.mergePatch on passed obj at specific path
  mergeAtPath(obj, path, value):: (
    $._T('mergeAtPath()', std.mergePatch(obj, $.setAtPath(path, value)))
  ),
}
