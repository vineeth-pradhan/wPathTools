( function _Glob_s_() {

'use strict';

/**
 * @file Glob.s.
 */

if( typeof module !== 'undefined' )
{

  let _ = require( '../../Tools.s' );
  _.include( 'wPathBasic' );
  _.include( 'wStringsExtra' );

}

//

let _global = _global_;
let _ = _global_.wTools;
let Self = _.path = _.path || Object.create( null );

// --
// functor
// --

function _vectorize( routine, select )
{
  _.assert( arguments.length === 1 || arguments.length === 2 );
  select = select || 1;
  return _.routineVectorize_functor
  ({
    routine : routine,
    vectorizingArray : 1,
    vectorizingMapVals : 0,
    vectorizingMapKeys : 1,
    select,
  });
}

// --
// simple transformer
// --

/*
(\*\*)| -- **
([?*])| -- ?*
(\[[!^]?.*\])| -- [!^]
([+!?*@]\(.*\))| -- @+!?*()
(\{.*\}) -- {}
(\(.*\)) -- ()
*/

// let transformation1 =
// [
//   [ /\[(.+?)\]/g, handleSquareBrackets ], /* square brackets */
//   [ /\{(.*)\}/g, handleCurlyBrackets ], /* curly brackets */
// ]
//
// let transformation2 =
// [
//   [ /\.\./g, '\\.\\.' ], /* double dot */
//   [ /\./g, '\\.' ], /* dot */
//   [ /([!?*@+]*)\((.*?(?:\|(.*?))*)\)/g, hanleParentheses ], /* parentheses */
//   [ /\/\*\*/g, '(?:\/.*)?', ], /* slash + double asterix */
//   [ /\*\*/g, '.*', ], /* double asterix */
//   [ /(\*)/g, '[^\/]*' ], /* single asterix */
//   [ /(\?)/g, '.', ], /* question mark */
// ]


// let _pathIsGlobRegexp = /(\*\*)|([?*])|(\[[!^]?.*\])|([+!?*@]?)|\{.*\}|(\(.*\))/;

let _pathIsGlobRegexpStr = '';
_pathIsGlobRegexpStr += '(?:[?*]+)'; /* asterix, question mark */
_pathIsGlobRegexpStr += '|(?:([!?*@+]*)\\((.*?(?:\\|(.*?))*)\\))'; /* parentheses */
_pathIsGlobRegexpStr += '|(?:\\[(.+?)\\])'; /* square brackets */
_pathIsGlobRegexpStr += '|(?:\\{(.*)\\})'; /* curly brackets */
_pathIsGlobRegexpStr += '|(?:\0)'; /* zero */

let _pathIsGlobRegexp = new RegExp( _pathIsGlobRegexpStr );

function _fromGlob( glob )
{
  let self = this;
  let result;

  _.assert( _.strIs( glob ), () => 'Expects string {-glob-}, but got ' + _.strType( glob ) );
  _.assert( arguments.length === 1, 'Expects single argument' );

  if( glob === '' || glob === null )
  return glob;

  let i = glob.search( _pathIsGlobRegexp );

  if( i >= 0 )
  {

    while( i >= 0 && glob[ i ] !== self._upStr )
    i -= 1;

    if( i === -1 )
    result = '';
    else
    result = glob.substr( 0, i+1 );

  }
  else
  {
    result = glob;
  }

  result = self.detrail( result || self._hereStr );
  // result = self.detrail( result );

  _.assert( !self.isGlob( result ) );

  return result;
}

//

function globNormalize( glob )
{
  let result = _.strReplaceAll( glob, { '()' : '', '*()' : '', '\0' : '' } ); /* xxx : cover */
  return result;
}

//

function _globSplit( glob )
{
  let self = this;

  _.assert( _.strIs( glob ), 'Expects string {-glob-}' );

  let splits = self.split( glob );

  for( let s = splits.length-1 ; s >= 0 ; s-- )
  {
    let split = splits[ s ];
    if( split === '**' || !_.strHas( split, '**' ) )
    continue;

    split = _.strSplitFast({ src : split, delimeter : '**', preservingEmpty : 0 });

    for( let i = 0 ; i < split.length ; i++ )
    {
      if( split[ i ] === '**' )
      continue;
      if( i > 0 )
      split[ i ] = '*' + split[ i ];
      if( i < split.length-1 )
      split[ i ] = split[ i ] + '*';
    }

    _.arrayCutin( splits, [ s, s+1 ], split );

  }

  return splits;
}

//

function _certainlySplitsFromActual( splits )
{
  let self = this;

  _.assert( _.arrayIs( splits ) );

  splits = splits.slice();

  let i = splits.length - 1;
  while( i >= 0 )
  {
    let split = splits[ i ];
    if( split !== '**' && split !== '*' )
    break;
    i -= 1;
  }

  return splits.slice( 0, i+1 );
}

//

function _globSplitToRegexpSource( src )
{

  _.assert( _.strIs( src ) );
  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( !_.strHas( src, this._downStr ) || src === this._downStr, 'glob should not has splits with ".." combined with something' );

  let transformation1 =
  [
    [ /\[(.+?)\]/g, handleSquareBrackets ], /* square brackets */
    [ /\{(.*)\}/g, handleCurlyBrackets ], /* curly brackets */
  ]

  let transformation2 =
  [
    [ /\.\./g, '\\.\\.' ], /* double dot */
    [ /\./g, '\\.' ], /* dot */
    [ /([!?*@+]*)\((.*?(?:\|(.*?))*)\)/g, hanleParentheses ], /* parentheses */
    [ /\/\*\*/g, '(?:\/.*)?', ], /* slash + double asterix */
    [ /\*\*/g, '.*', ], /* double asterix */
    [ /(\*)/g, '[^\/]*' ], /* single asterix */
    [ /(\?)/g, '.', ], /* question mark */
  ]

  let result = adjustGlobStr( src );

  return result;

  /* */

  function handleCurlyBrackets( src, it )
  {
    debugger;
    throw _.err( 'Globs with curly brackets are not supported' );
  }

  /* */

  function handleSquareBrackets( src, it )
  {
    let inside = it.groups[ 0 ];
    /* escape inner [] */
    inside = inside.replace( /[\[\]]/g, ( m ) => '\\' + m );
    /* replace ! -> ^ at the beginning */
    inside = inside.replace( /^!/g, '^' );
    if( inside[ 0 ] === '^' )
    inside = inside + '\/';
    return '[' + inside + ']';
  }

  /* */

  function hanleParentheses( src, it )
  {

    let inside = it.groups[ 1 ].split( '|' );
    let multiplicator = it.groups[ 0 ];

    multiplicator = _.strReverse( multiplicator );
    if( multiplicator === '*' )
    multiplicator += '?';

    _.assert( _.strCount( multiplicator, '!' ) === 0 || multiplicator === '!' );
    _.assert( _.strCount( multiplicator, '@' ) === 0 || multiplicator === '@' );

    let result = '(?:' + inside.join( '|' ) + ')';
    if( multiplicator === '@' )
    result = result;
    else if( multiplicator === '!' )
    result = '(?:(?!(?:' + result + '|\/' + ')).)*?';
    else
    result += multiplicator;

    /* (?:(?!(?:abc)).)+ */

    return result;
  }

  /* */

  function adjustGlobStr( src )
  {
    let result = src;

    result = _.strReplaceAll( result, transformation1 );
    result = _.strReplaceAll( result, transformation2 );

    return result;
  }

}

// --
// short filter
// --

function globSplitToRegexp( glob )
{
  _.assert( _.strIs( glob ) || _.regexpIs( glob ) );
  _.assert( arguments.length === 1 );

  if( _.regexpIs( glob ) )
  return glob;

  let str = this._globSplitToRegexpSource( glob );
  let result = new RegExp( '^' + str + '$' );
  return result;
}

//

function globFilter_pre( routine, args )
{
  let result;

  _.assert( arguments.length === 2 );
  _.assert( args.length === 1 || args.length === 2 );

  let o = args[ 0 ];
  if( args[ 1 ] !== undefined )
  o = { src : args[ 0 ], selector : args[ 1 ] }

  o = _.routineOptions( routine, o );

  if( o.onEvaluate === null )
  o.onEvaluate = function byVal( e, k, src )
  {
    return e;
  }

  return o;
}

//

function globFilter_body( o )
{
  let result;

  _.assert( arguments.length === 1 );

  if( !this.isGlob( o.selector ) )
  {
    result = _.filter( o.src, ( e, k ) =>
    {
      return o.onEvaluate( e, k, o.src ) === o.selector ? e : undefined;
    });
  }
  else
  {
    let regexp = this.globsShortToRegexps( o.selector );
    result = _.filter( o.src, ( e, k ) =>
    {
      return regexp.test( o.onEvaluate( e, k, o.src ) ) ? e : undefined;
    });
  }

  return result;
}

globFilter_body.defaults =
{
  src : null,
  selector : null,
  onEvaluate : null,
}

let globFilter = _.routineFromPreAndBody( globFilter_pre, globFilter_body );

let globFilterVals = _.routineFromPreAndBody( globFilter_pre, globFilter_body );
globFilterVals.defaults.onEvaluate = function byVal( e, k, src )
{
  return e;
}

let globFilterKeys = _.routineFromPreAndBody( globFilter_pre, globFilter_body );
globFilterKeys.defaults.onEvaluate = function byKey( e, k, src )
{
  return _.arrayIs( src ) ? e : k;
}

// --
// full filter
// --

function _globRegexpSourceSplitsConcatWithSlashes( globRegexpSourceSplits )
{
  let result = '';

  /*
    asterisk and double-asterisk are optional elements of pattern
    so them could be missing
  */

  let splits = globRegexpSourceSplits.map( ( split, s ) =>
  {
    if( s > 0 )
    if( split === '.*' )
    split = '(?:(?:^|/)' + split + ')?';
    else if( split === '[^\/]*' )
    split = '(?:(?:^|/)' + split + ')?';
    else
    split = '(?:^|/)' + split;
    return split;
  });

  return splits;
}

//

function _globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits )
{
  let self = this;
  let splits = self._globRegexpSourceSplitsConcatWithSlashes( globRegexpSourceSplits );
  let result = splits.join( '' );
  return result;
}

//

function _globRegexpSourceSplitsJoinForDirectory( globRegexpSourceSplits )
{
  let self = this;
  let splits = self._globRegexpSourceSplitsConcatWithSlashes( globRegexpSourceSplits );
  let result = _.regexpsAtLeastFirst( splits ).source;
  return result;
}

//

function _relateForGlob( glob, stemPath, basePath )
{
  let self = this;
  let result = [];

  _.assert( arguments.length === 3, 'Expects exactly three arguments' );
  _.assert( _.strIs( glob ), 'Expects string {-glob-}' );
  _.assert( _.strIs( stemPath ), 'Expects string' );
  _.assert( _.strIs( basePath ) );
  _.assert( !self.isRelative( glob ) ^ self.isRelative( stemPath ), 'Expects both relative path either absolute' );

  glob = this.globNormalize( glob );
  glob = this.join( stemPath, glob );

  _.assert( self.isGlob( glob ), () => 'Expects glob, but got ' + glob );

  let globDir = this.fromGlob( glob );

  let globRelativeBase = this.relative( basePath, glob );
  let globDirRelativeBase = this.relative( basePath, globDir );
  let stemRelativeBase = this.relative( basePath, stemPath );

  let baseRelativeGlobDir = this.relative( globDir, basePath );
  let baseRelativeStem = this.relative( stemPath, basePath );

  let globRelativeStem = this.relative( stemPath, glob );
  let globDirRelativeStem = this.relative( stemPath, globDir );
  let stemRelativeGlobDir = this.relative( globDir, stemPath );
  let globRelativeGlobDir = this.relative( globDir, glob );

  if( globDirRelativeBase === self._hereStr && stemRelativeBase === self._hereStr )
  {

    result.push( self.dot( globRelativeBase ) );

  }
  else
  {

    // debugger;
    if( isDotted( stemRelativeGlobDir ) )
    {

      let globSplits = this._globSplit( globRelativeGlobDir ).join( self._upStr );

      let glob3 = globSplits;
      if( globDirRelativeStem !== self._hereStr )
      glob3 = globDirRelativeStem + self._upStr + glob3;
      if( stemRelativeGlobDir === self._hereStr )
      {
        glob3 = globDirRelativeBase + self._upStr + glob3;
      }
      else
      {
        if( stemRelativeBase !== self._hereStr )
        glob3 = stemRelativeBase + self._upStr + glob3;
      }
      _.arrayAppendOnce( result, self.dot( glob3 ) );

      if( self.begins( globDir, basePath ) || self.begins( basePath, globDir ) )
      {
        let glob4 = globSplits;
        if( !isDotted( globDirRelativeBase ) )
        glob4 = globDirRelativeBase + self._upStr + glob4;
        _.arrayAppendOnce( result, self.dot( glob4 ) );
      }
      // else
      // logger.log( '*' );

    }
    else
    {

      let globSplits = this._globSplit( globRelativeGlobDir );
      let globRegexpSourceSplits = globSplits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );

      let s = 0;
      let firstAny = globSplits.length;
      while( s < globSplits.length )
      {
        if( globSplits[ s ] === '**' )
        {
          firstAny = s;
        }
        let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
        if( globSliced.test( baseRelativeStem ) )
        {

          let splits3 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
          if( isDotted( stemRelativeGlobDir ) )
          _.arrayPrependArray( splits3, self.split( baseRelativeStem ) );
          _.arrayPrependArray( splits3, self.split( stemRelativeBase ) );
          let glob3 = splits3.join( self._upStr );
          _.arrayAppendOnce( result, self.dot( glob3 ) );

          let splits4 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
          let glob4 = splits4.join( self._upStr );
          _.arrayAppendOnce( result, self.dot( glob4 ) );

          if( firstAny < globSplits.length )
          break;
        }
        s += 1;
      }

    }

    // debugger;
    // // if( stemRelativeGlobDir === self._hereStr )
    // if( isDotted( stemRelativeGlobDir ) )
    // {
    //
    //   // let globSplits = this._globSplit( globRelativeStem );
    //   // let globSplits = this._globSplit( globRelativeCommon );
    //   let globSplits = this._globSplit( globRelativeGlobDir );
    //   // let globRegexpSourceSplits = globSplits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );
    //
    //   let splits3 = globSplits.slice();
    //   if( globDirRelativeStem !== self._hereStr )
    //   _.arrayPrependArray( splits3, self.split( globDirRelativeStem ) );
    //   if( stemRelativeGlobDir === self._hereStr )
    //   {
    //     _.arrayPrependArray( splits3, self.split( globDirRelativeBase ) );
    //   }
    //   else
    //   {
    //     // _.arrayPrependArray( splits3, self.split( baseRelativeStem ) );
    //     if( stemRelativeBase !== self._hereStr )
    //     _.arrayPrependArray( splits3, self.split( stemRelativeBase ) );
    //   }
    //
    //   let glob3 = splits3.join( self._upStr );
    //   _.arrayAppendOnce( result, self.dot( glob3 ) );
    //
    //   let splits4 = globSplits.slice();
    //   // if( globDirRelativeStem !== self._hereStr )
    //   // _.arrayPrependArray( splits4, self.split( globDirRelativeStem ) );
    //   // if( globDirRelativeBase !== self._hereStr )
    //   if( !isDotted( globDirRelativeBase ) )
    //   _.arrayPrependArray( splits4, self.split( globDirRelativeBase ) );
    //   let glob4 = splits4.join( self._upStr );
    //   _.arrayAppendOnce( result, self.dot( glob4 ) );
    //
    // }
    // else
    // {
    //
    //   let globSplits = this._globSplit( globRelativeCommon );
    //   let globRegexpSourceSplits = globSplits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );
    //
    //   let s = 0;
    //   let firstAny = globSplits.length;
    //   while( s < globSplits.length )
    //   {
    //     if( globSplits[ s ] === '**' )
    //     {
    //       firstAny = s;
    //     }
    //     let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
    //     if( globSliced.test( baseRelativeStem ) )
    //     {
    //
    //       let splits3 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
    //       if( isDotted( stemRelativeGlobDir ) )
    //       _.arrayPrependArray( splits3, self.split( baseRelativeStem ) );
    //       _.arrayPrependArray( splits3, self.split( stemRelativeBase ) );
    //       let glob3 = splits3.join( self._upStr );
    //       _.arrayAppendOnce( result, self.dot( glob3 ) );
    //
    //       let splits4 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
    //       let glob4 = splits4.join( self._upStr );
    //       _.arrayAppendOnce( result, self.dot( glob4 ) );
    //
    //       if( firstAny < globSplits.length )
    //       break;
    //     }
    //     s += 1;
    //   }
    //
    // }

    // debugger;
    // if( !isDotted( baseRelativeStem ) )
    // {
    //
    //   _.assert( _.strBegins( stemRelativeBase, '..' ), 'not tested' );
    //   let s = 0;
    //   let firstAny = globSplits.length;
    //   while( s < globSplits.length )
    //   {
    //     if( globSplits[ s ] === '**' )
    //     {
    //       firstAny = s;
    //     }
    //     let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
    //     if( globSliced.test( baseRelativeStem ) )
    //     {
    //
    //       let splits3 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
    //       if( isDotted( stemRelativeGlobDir ) )
    //       _.arrayPrependArray( splits3, self.split( baseRelativeStem ) );
    //       _.arrayPrependArray( splits3, self.split( stemRelativeBase ) );
    //       let glob3 = splits3.join( self._upStr );
    //       _.arrayAppendOnce( result, self.dot( glob3 ) );
    //
    //       let splits4 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
    //       let glob4 = splits4.join( self._upStr );
    //       _.arrayAppendOnce( result, self.dot( glob4 ) );
    //
    //       if( firstAny < globSplits.length )
    //       break;
    //     }
    //     s += 1;
    //   }
    //
    // }
    // else
    // {
    //
    //   if( isDotted( baseRelativeGlobDir ) )
    //   {
    //     debugger;
    //     let downGlob2 = self.dot( self.relative( basePath, glob ) );
    //     result.push( downGlob2 );
    //   }
    //   else
    //   {
    //
    //     let s = 0;
    //     let firstAny = globSplits.length;
    //     while( s < globSplits.length )
    //     {
    //       if( globSplits[ s ] === '**' )
    //       {
    //         firstAny = s;
    //       }
    //       let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
    //       if( globSliced.test( baseRelativeGlobDir ) )
    //       {
    //
    //         let splits3 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
    //         _.arrayPrependArray( splits3, self.split( baseRelativeGlobDir ) );
    //         _.arrayPrependArray( splits3, self.split( globDirRelativeBase ) );
    //         let glob3 = splits3.join( self._upStr );
    //         _.arrayAppendOnce( result, self.dot( glob3 ) );
    //
    //         let splits4 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
    //         let glob4 = splits4.join( self._upStr );
    //         _.arrayAppendOnce( result, self.dot( glob4 ) );
    //
    //         if( firstAny < globSplits.length )
    //         break;
    //       }
    //       s += 1;
    //     }
    //
    //   }
    //
    // }

  }

  return result;

  function isDotted( filePath )
  {
    return filePath === self._hereStr || filePath === self._downStr || _.strBegins( filePath, self._downStr );
  }

  function isUp( filePath )
  {
    return filePath === self._downStr || _.strBegins( filePath, self._downStr );
  }

}

//

// function _relateForGlob( glob, stemPath, basePath )
// {
//   let self = this;
//   let result = [];
//
//   _.assert( arguments.length === 3, 'Expects exactly three arguments' );
//   _.assert( _.strIs( glob ), 'Expects string {-glob-}' );
//   _.assert( _.strIs( stemPath ), 'Expects string' );
//   _.assert( _.strIs( basePath ) );
//   _.assert( !self.isRelative( glob ) ^ self.isRelative( stemPath ), 'Expects both relative path either absolute' );
//
//   glob = this.globNormalize( glob );
//   glob = this.join( stemPath, glob );
//   let globDir = this.fromGlob( glob );
//   let common = this.common( glob, basePath );
//
//   let globRelativeBase = this.relative( basePath, glob );
//   let globDirRelativeBase = this.relative( basePath, globDir );
//   let stemRelativeBase = this.relative( basePath, stemPath );
//
//   let baseRelativeGlob = this.relative( glob, basePath );
//   let baseRelativeGlobDir = this.relative( globDir, basePath );
//   let baseRelativeStem = this.relative( stemPath, basePath );
//
//   let globRelativeStem = this.relative( stemPath, glob );
//   let globDirRelativeStem = this.relative( stemPath, globDir );
//   let stemRelativeGlobDir = this.relative( globDir, stemPath );
//   // let baseRelativeStem = this.relative( stemPath, basePath );
//
//   let globRelativeCommon = this.relative( common, glob );
//   let baseRelativeCommon = this.relative( common, basePath );
//
//   // debugger;
//
//   if( globDirRelativeBase === self._hereStr && stemRelativeBase === self._hereStr )
//   // if( baseRelativeCommon === '.' )
//   {
//
//     result.push( self.dot( globRelativeBase ) );
//     // result.push( ( globRelativeBase === '' || globRelativeBase === '.' ) ? '.' : './' + globRelativeBase );
//
//   }
//   else
//   {
//
//     // debugger;
//     // if( 0 )
//     // if( baseRelativeStem !== '.' )
//     // {
//     //   // debugger;
//     //   let downGlob2 = self.relative( stemPath, glob ); // yyy
//     //   result.push( downGlob2 );
//     // }
//
//     let globSplits = this._globSplit( globRelativeCommon );
//     let globRegexpSourceSplits = globSplits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );
//
//     // let globPath = self.fromGlob( glob );
//     // let globPathRelativeFilePath = self.relative( globPath, stemPath );
//     // let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits ) + '$' );
//     // if( globSliced.test( baseRelativeStem ) )
//     // {
//     //   debugger;
//     //   _.arrayAppendOnce( result, '**' );
//     //   return result;
//     // }
//
//     debugger;
//     if( !isDotted( baseRelativeStem ) )
//     {
//
//       // let downGlob2 = self.relative( basePath, glob );
//       // result.push( downGlob2 );
//
//       // if( isDotted( baseRelativeGlobDir ) )
//       // {
//       //   debugger;
//       //   let downGlob2 = self.dot( self.relative( basePath, glob ) );
//       //   result.push( downGlob2 );
//       // }
//
//       _.assert( _.strBegins( stemRelativeBase, '..' ), 'not tested' );
//       let s = 0;
//       let firstAny = globSplits.length;
//       while( s < globSplits.length )
//       {
//         if( globSplits[ s ] === '**' )
//         {
//           firstAny = s;
//         }
//         let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
//         if( globSliced.test( baseRelativeStem ) )
//         {
//
//           let splits3 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
//           if( isDotted( stemRelativeGlobDir ) )
//           _.arrayPrependArray( splits3, self.split( baseRelativeStem ) );
//           _.arrayPrependArray( splits3, self.split( stemRelativeBase ) );
//           let glob3 = splits3.join( self._upStr );
//           _.arrayAppendOnce( result, self.dot( glob3 ) );
//
//           let splits4 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
//           let glob4 = splits4.join( self._upStr );
//           _.arrayAppendOnce( result, self.dot( glob4 ) );
//
//           if( firstAny < globSplits.length )
//           break;
//         }
//         s += 1;
//       }
//
//     }
//     else
//     {
//
//       if( isDotted( baseRelativeGlobDir ) )
//       {
//         debugger;
//         let downGlob2 = self.dot( self.relative( basePath, glob ) );
//         result.push( downGlob2 );
//       }
//       else
//       {
//
//         let s = 0;
//         let firstAny = globSplits.length;
//         while( s < globSplits.length )
//         {
//           if( globSplits[ s ] === '**' )
//           {
//             firstAny = s;
//           }
//           let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
//           if( globSliced.test( baseRelativeGlobDir ) )
//           {
//
//             let splits3 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
//             _.arrayPrependArray( splits3, self.split( baseRelativeGlobDir ) );
//             _.arrayPrependArray( splits3, self.split( globDirRelativeBase ) );
//             let glob3 = splits3.join( self._upStr );
//             _.arrayAppendOnce( result, self.dot( glob3 ) );
//
//             let splits4 = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
//             let glob4 = splits4.join( self._upStr );
//             _.arrayAppendOnce( result, self.dot( glob4 ) );
//
//             if( firstAny < globSplits.length )
//             break;
//           }
//           s += 1;
//         }
//
//       }
//
//       // let s = 0;
//       // let firstAny = globSplits.length;
//       // while( s < globSplits.length )
//       // {
//       //   if( globSplits[ s ] === '**' )
//       //   {
//       //     firstAny = s;
//       //   }
//       //   let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
//       //   if( globSliced.test( baseRelativeStem ) )
//       //   {
//       //     let splits = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
//       //     let glob3 = splits.join( self._upStr );
//       //     _.arrayAppendOnce( result, glob3 === '' ? '.' : './' + glob3  );
//       //     if( firstAny < globSplits.length )
//       //     break;
//       //   }
//       //   s += 1;
//       // }
//
//     }
//
//   }
//
//   return result;
//
//   function isDotted( filePath )
//   {
//     return filePath === self._hereStr || filePath === self._downStr || _.strBegins( filePath, self._downStr );
//   }
//
//   function isUp( filePath )
//   {
//     return filePath === self._downStr || _.strBegins( filePath, self._downStr );
//   }
//
// }

// function _relateForGlob( glob, stemPath, basePath )
// {
//   let self = this;
//   let result = [];
//
//   _.assert( arguments.length === 3, 'Expects exactly three arguments' );
//   _.assert( _.strIs( glob ), 'Expects string {-glob-}' );
//   _.assert( _.strIs( stemPath ), 'Expects string' );
//   _.assert( _.strIs( basePath ) );
//   _.assert( !self.isRelative( glob ) ^ self.isRelative( stemPath ), 'Expects both relative path either absolute' );
//
//   debugger;
//
//   glob = this.globNormalize( glob );
//   glob = this.join( stemPath, glob );
//   let common = this.common( glob, basePath );
//   let glob2 = this.relative( common, glob );
//   let baseRelativeCommon = this.relative( common, basePath );
//
//   if( baseRelativeCommon === '.' )
//   {
//
//     result.push( ( glob2 === '' || glob2 === '.' ) ? '.' : './' + glob2 );
//
//   }
//   else
//   {
//
//     debugger;
//     let downGlob2 = self.relative( stemPath, glob );
//     result.push( downGlob2 );
//
//     let globSplits = this._globSplit( glob2 );
//     let globRegexpSourceSplits = globSplits.map( ( e, i ) => self._globSplitToRegexpSource( e ) );
//
//     // let globPath = self.fromGlob( glob );
//     // let globPathRelativeFilePath = self.relative( globPath, stemPath );
//     // let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits ) + '$' );
//     // if( globSliced.test( baseRelativeCommon ) )
//     // {
//     //   debugger;
//     //   _.arrayAppendOnce( result, '**' );
//     //   return result;
//     // }
//
//     let s = 0;
//     let firstAny = globSplits.length;
//     while( s < globSplits.length )
//     {
//       if( globSplits[ s ] === '**' )
//       {
//         firstAny = s;
//       }
//       let globSliced = new RegExp( '^' + self._globRegexpSourceSplitsJoinForTerminal( globRegexpSourceSplits.slice( 0, s+1 ) ) + '$' );
//       if( globSliced.test( baseRelativeCommon ) )
//       {
//         let splits = firstAny < globSplits.length ? globSplits.slice( firstAny ) : globSplits.slice( s+1 );
//         let glob3 = splits.join( self._upStr );
//         _.arrayAppendOnce( result, glob3 === '' ? '.' : './' + glob3  );
//         if( firstAny < globSplits.length )
//         break;
//       }
//       s += 1;
//     }
//
//   }
//
//   return result;
// }

//

function _globFullToRegexpSingle( glob, stemPath, basePath )
{
  let self = this;

  _.assert( _.strIs( glob ), 'Expects string {-glob-}' );
  _.assert( _.strIs( stemPath ) && !_.path.isGlob( stemPath ) );
  _.assert( _.strIs( basePath ) && !_.path.isGlob( basePath ) );
  _.assert( arguments.length === 3 );

  glob = self.join( stemPath, glob );

  let related = self._relateForGlob( glob, stemPath, basePath );
  let maybeHere = '';
  let hereEscapedStr = self._globSplitToRegexpSource( self._hereStr );
  let downEscapedStr = self._globSplitToRegexpSource( self._downStr );

  let cache = Object.create( null );
  let result = Object.create( null );
  result.transient = [];
  result.actual = [];
  result.certainly = [];

  for( let r = 0 ; r < related.length ; r++ )
  {

    let actualSplits = self.split( related[ r ] );
    let transientSplits = self._globSplit( related[ r ] );
    let certainlySplits = self._certainlySplitsFromActual( actualSplits );
    if( certainlySplits.length === actualSplits.length )
    certainlySplits = [];

    actualSplits = actualSplits.map( ( e, i ) => toRegexp( e ) );
    transientSplits = transientSplits.map( ( e, i ) => toRegexp( e ) );
    certainlySplits = certainlySplits.map( ( e, i ) => toRegexp( e ) );

    result.actual.push( self._globRegexpSourceSplitsJoinForTerminal( actualSplits ) );
    result.transient.push( self._globRegexpSourceSplitsJoinForDirectory( transientSplits ) );
    if( certainlySplits.length )
    result.certainly.push( self._globRegexpSourceSplitsJoinForTerminal( certainlySplits ) );

  }

  result.transient = '(?:(?:' + result.transient.join( ')|(?:' ) + '))';
  result.transient = _.regexpsJoin([ '^', result.transient, '$' ]);

  result.actual = '(?:(?:' + result.actual.join( ')|(?:' ) + '))';
  result.actual = _.regexpsJoin([ '^', result.actual, '$' ]);

  if( result.certainly.length )
  {
    result.certainly = '(?:(?:' + result.certainly.join( ')|(?:' ) + '))';
    result.certainly = _.regexpsJoin([ '^', result.certainly, '$' ]);
  }
  else
  {
    result.certainly = null;
  }

  return result;

  /* - */

  function toRegexp( split )
  {
    if( cache[ split ] )
    return cache[ split ];
    cache[ split ] = self._globSplitToRegexpSource( split );
    return cache[ split ];
  }

}

//

// debugger;
// let _globsFullToRegexps = _.routineVectorize_functor
// // let _globsFullToRegexps = _.path.s._vectorize
// ({
//   routine : _globFullToRegexpSingle,
//   select : 3,
// });

//

function globsFullToRegexps()
{
  let r = this._globsFullToRegexps.apply( this, arguments );
  if( _.arrayIs( r ) )
  {
    let result = Object.create( null );
    result.actual = r.map( ( e ) => e.actual );
    result.transient = r.map( ( e ) => e.transient );
    return result;
  }
  return r;
}

//

function pathMapToRegexps( o )
{
  let path = this;

  if( arguments[ 1 ] !== undefined )
  o = { filePath : arguments[ 0 ], basePath : arguments[ 1 ] }

  _.routineOptions( pathMapToRegexps, o );
  _.assert( arguments.length === 1 || arguments.length === 2 );
  _.assert( _.mapIs( o.basePath ) );
  _.assert( _.mapIs( o.filePath ) )

  /* has only booleans */

  let hasOnlyBools = 1;
  for( let srcGlob in o.filePath )
  {
    let dstPath = o.filePath[ srcGlob ];
    if( !_.boolLike( dstPath ) )
    {
      hasOnlyBools = 0;
      break;
    }
  }

  if( hasOnlyBools )
  {
    for( let srcGlob in o.filePath )
    if( _.boolLike( o.filePath[ srcGlob ] ) && o.filePath[ srcGlob ] )
    o.filePath[ srcGlob ] = null;
  }

  /* unglob filePath */

  o.fileGlobToPathMap = Object.create( null );
  o.filePathToGlobMap = Object.create( null );
  o.unglobedFilePath = Object.create( null );
  for( let srcGlob in o.filePath )
  {
    let dstPath = o.filePath[ srcGlob ];

    if( dstPath === null )
    dstPath = '';

    _.assert( path.isAbsolute( srcGlob ), () => 'Expects absolute path, but ' + _.strQuote( srcGlob ) + ' is not' );

    let srcPath = path.fromGlob( srcGlob );

    o.fileGlobToPathMap[ srcGlob ] = srcPath;
    o.filePathToGlobMap[ srcPath ] = o.filePathToGlobMap[ srcPath ] || [];
    o.filePathToGlobMap[ srcPath ].push( srcGlob );
    let wasUnglobedFilePath = o.unglobedFilePath[ srcPath ];
    if( wasUnglobedFilePath === undefined || _.boolLike( wasUnglobedFilePath ) )
    // if( !_.boolLike( dstPath ) || dstPath || wasUnglobedFilePath === undefined ) // yyy
    if( !_.boolLike( dstPath ) )
    {
      _.assert( wasUnglobedFilePath === undefined || _.boolLike( wasUnglobedFilePath ) || wasUnglobedFilePath === dstPath );
      o.unglobedFilePath[ srcPath ] = dstPath;
    }

  }

  /* unglob basePath */

  o.unglobedBasePath = Object.create( null );
  for( let fileGlob in o.basePath )
  {
    _.assert( path.isAbsolute( fileGlob ) );
    _.assert( !path.isGlob( o.basePath[ fileGlob ] ) );

    let filePath;
    let basePath = o.basePath[ fileGlob ];
    if( o.filePath[ fileGlob ] === undefined )
    {
      filePath = fileGlob;
      fileGlob = o.filePathToGlobMap[ filePath ];
    }

    if( _.arrayIs( filePath ) )
    filePath.forEach( ( filePath ) => unglobedBasePathAdd( fileGlob, filePath, basePath ) );
    else
    unglobedBasePathAdd( fileGlob, filePath, basePath )

  }

  /* group by path */

  o.redundantMap = _.mapExtend( null, o.filePath );
  o.groupedMap = Object.create( null );
  for( let fileGlob in o.redundantMap )
  {

    let value = o.redundantMap[ fileGlob ];
    let filePath = o.fileGlobToPathMap[ fileGlob ];
    let group = { [ fileGlob ] : value };

    if( _.boolLike( value ) )
    {
      continue;
    }

    delete o.redundantMap[ fileGlob ];

    for( let fileGlob2 in o.redundantMap )
    {
      let value2 = o.redundantMap[ fileGlob2 ];
      let filePath2 = o.fileGlobToPathMap[ fileGlob2 ];
      let begin;

      _.assert( fileGlob !== fileGlob2 );

      if( path.begins( filePath, filePath2 ) )
      begin = filePath2;
      else if( path.begins( filePath2, filePath ) )
      begin = filePath;

      /* skip if different group */
      if( !begin )
      continue;

      if( _.boolLike( o.redundantMap[ fileGlob2 ] ) )
      {
        group[ fileGlob2 ] = value2;
      }
      else
      {
        if( filePath === filePath2 )
        {
          group[ fileGlob2 ] = value2;
          delete o.redundantMap[ fileGlob2 ];
        }
      }

    }

    let commonPath = filePath;
    for( let fileGlob2 in group )
    {
      let value2 = o.filePath[ fileGlob2 ];

      if( _.boolLike( value2 ) )
      continue;

      let filePath2 = o.fileGlobToPathMap[ fileGlob2 ];
      if( filePath2.length < commonPath.length )
      commonPath = filePath2;

    }

    _.assert( o.groupedMap[ commonPath ] === undefined );
    o.groupedMap[ commonPath ] = group;

  }

  /* */

  o.regexpMap = Object.create( null );
  for( let commonPath in o.groupedMap )
  {
    let group = o.groupedMap[ commonPath ];
    let basePath = o.unglobedBasePath[ commonPath ];
    let r = o.regexpMap[ commonPath ] = Object.create( null );
    r.certainlyHash = new Map;
    r.transient = [];
    r.actualAny = [];
    r.actualAll = [];
    r.actualNone = [];

    _.assert( _.strDefined( basePath ), 'No base path for', commonPath );

    for( let fileGlob in group )
    {
      let value = group[ fileGlob ];

      // if( !path.isGlob( fileGlob ) ) yyy
      // fileGlob = path.join( fileGlob, '**' ); yyy

      if( !path.isGlob( fileGlob ) )
      {
        if( commonPath !== fileGlob || _.boolLike( value ) )
        fileGlob = path.join( fileGlob, '**' );
        else
        continue;
      }

      // debugger;
      let regexps = path._globFullToRegexpSingle( fileGlob, commonPath, basePath );
      // debugger;

      if( regexps.certainly )
      r.certainlyHash.set( regexps.actual, regexps.certainly )

      if( value || value === null || value === '' )
      {
        if( _.boolLike( value ) )
        {
          r.actualAll.push( regexps.actual );
        }
        else
        {
          r.actualAny.push( regexps.actual );
        }
        r.transient.push( regexps.transient )
      }
      else
      {
        r.actualNone.push( regexps.actual );
      }

    }

  }

  return o;

  /* */

  function unglobedBasePathAdd( fileGlob, filePath, basePath )
  {
    _.assert( _.strIs( fileGlob ) );
    _.assert( filePath === undefined || _.strIs( filePath ) );
    _.assert( _.strIs( basePath ) );
    _.assert( o.filePath[ fileGlob ] !== undefined, () => 'No file path for file glob ' + g );

    if( _.boolLike( o.filePath[ fileGlob ] ) )
    return;

    if( !filePath )
    filePath = path.fromGlob( fileGlob );

    _.assert
    (
      o.unglobedBasePath[ filePath ] === undefined || o.unglobedBasePath[ filePath ] === basePath,
      () => 'The same file path ' + _.strQuote( filePath ) + ' has several different base paths:' +
      '\n - ' + _.strQuote( o.unglobedBasePath[ filePath ] ),
      '\n - ' + _.strQuote( basePath )
    );
    o.unglobedBasePath[ filePath ] = basePath;
  }

}

pathMapToRegexps.defaults =
{
  filePath : null,
  basePath : null,
  samePathOnly : 1,
}

// --
// fields
// --

let Fields =
{
}

// --
// routines
// --

let Routines =
{

  // simple transformer

  _fromGlob,
  // fromGlob : _.routineVectorize_functor( _fromGlob ),
  fromGlob : _vectorize( _fromGlob ),
  globNormalize,
  _globSplit,
  _certainlySplitsFromActual,
  _globSplitToRegexpSource,

  // short filter

  globSplitToRegexp,
  // globsShortToRegexps : _.routineVectorize_functor( globSplitToRegexp ),
  globsShortToRegexps : _vectorize( globSplitToRegexp ),
  globFilter,
  globFilterVals,
  globFilterKeys,

  // full filter

  _globRegexpSourceSplitsConcatWithSlashes,
  _globRegexpSourceSplitsJoinForTerminal,
  _globRegexpSourceSplitsJoinForDirectory,
  _relateForGlob,
  _globFullToRegexpSingle,

  _globsFullToRegexps : _vectorize( _globFullToRegexpSingle, 3 ),

  globsFullToRegexps,
  pathMapToRegexps,

}

_.mapSupplement( Self, Fields );
_.mapSupplement( Self, Routines );

// Self.Init();

// --
// export
// --

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

// if( typeof module !== 'undefined' )
// {
//   require( '../l3/PathBasic.s' );
// }

})();
