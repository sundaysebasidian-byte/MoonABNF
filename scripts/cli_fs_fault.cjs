'use strict';
const fs = require('node:fs');
const path = require('node:path');
const target=process.env.REVIEW_FAULT_TARGET,mode=process.env.REVIEW_FAULT_MODE;
const open=fs.openSync,read=fs.readSync,close=fs.closeSync;
const owned=new Set();
fs.openSync=function(file,...args){
 const fd=open.call(this,file,...args);
 if(typeof file==='string'&&path.resolve(file)===target)owned.add(fd);
 return fd;
};
fs.readSync=function(fd,...args){
 if(owned.has(fd)&&['read','both'].includes(mode)){
  const e=new Error('INJECTED_READ_EIO');e.code='EIO';throw e;
 }
 return read.call(this,fd,...args);
};
fs.closeSync=function(fd,...args){
 const mine=owned.delete(fd);
 const result=close.call(this,fd,...args); // real close first; never strand an fd
 if(mine&&['close','both'].includes(mode)){
  process.stderr.write('FAULT_PROBE actual-close-completed-before-injected-error\n');
  const e=new Error('INJECTED_CLOSE_EIO');e.code='EIO';throw e;
 }
 return result;
};
process.on('exit',()=>{if(owned.size){process.stderr.write('FAULT_PROBE LEAKED_FDS='+owned.size+'\n');process.exitCode=99;}});
