const ErrorLine = require('./ErrorLine.js');

const style = {
  background: '#fff',
  padding: '20px 30px',
  fontSize: '12px',
  fontFamily: 'monospace',
};
const message = {
  fontSize: '12px',
  color: 'red',
  marginBottom: 20,
  whiteSpace: 'pre',
};
const code = {
  lineHeight: '1.5',
  whiteSpace: 'pre',
  fontFamily: 'monospace',
};
const table = {
  borderCollapse: 'collapse',
};

module.exports = function ErrorDetails(props) {
  const {lines, line, column} = props;
  return html('div', {style: style},
    html('h1', {style: message, key: 'h1'}, props.message),
    html('p', {key: 'p'}, 'in ' + props.path + ':'),
    html('table', {style: table, key: 'table'},
      html('tbody', {style: code},
        (lines || []).map((l, i) => {
          const args = {key: i, hasError: l.lineNum === line, column: column};
          return ErrorLine(Object.assign({}, l, args));
        })
      )
    )
  );
};
