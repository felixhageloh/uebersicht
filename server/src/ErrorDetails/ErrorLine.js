const codeLine = {
  padding: '0 10px',
  position: 'relative',
};
const lineNum = {
  color: '#787878',
  padding: '0 10px',
  borderRight: '0.5px solid #ddd',
};

const marker = {
  background: 'rgba(255, 0, 0, 0.3)',
  fontStyle: 'normal',
};

function slice(line, col) {
  return [
    line.slice(0, col),
    html('em', {style: marker, key: 'marker'}, line.slice(col, col + 1)),
    line.slice(col + 1),
  ];
}

module.exports = function ErrorLine(props) {
  const style = {
    background: props.hasError ? 'rgba(255, 0, 0, 0.2)' : '',
  };
  const content = props.hasError ? slice(props.line, props.column) : props.line;
  return html('tr', {key: props.key, style: style}, [
    html('td', {style: lineNum, key: props.key + '-0'}, props.lineNum),
    html('td', {style: codeLine, key: props.key + '-1'}, content),
  ]);
};
