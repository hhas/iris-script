#!usr/bin/env python3

from plistlib import *
from pprint import *
import re, os.path



types = set()

stdtypes = {
	# params
	'WFSwitchParameter': 'boolean',
	'WFTextInputParameter': 'string',
	'WFDateFieldParameter': 'date',
	'WFDatePickerParameter': 'date',
	'WFURLParameter': 'URL',
	'WFVariableFieldParameter': 'identifier',
	'WFVariablePickerParameter': 'identifier',
	'WFDynamicEnumerationParameter': 'dynamic_choice',
	'WFContentArrayParameter': 'ordered_list',
	'WFDictionaryParameter': 'keyed_list',
	# 'WFTimeIntervalParameter',
	# 'WFUnitQuantityFieldParameter',
	# 'WFUnitTypePickerParameter',
	# input/output
	'WFContentItem': 'item',
	'WFBooleanContentItem': 'boolean',
	'WFNumberContentItem': 'number',
	'WFStringContentItem': 'string',
	'WFDateContentItem': 'date',
	'WFArrayContentItem': 'ordered_list',
	'WFDictionaryContentItem': 'keyed_list',
	# 'WFTimeIntervalContentItem',
	# 'WFEmailAddressContentItem',
	# 'WFFileSizeContentItem',
	# 'WFGenericFileContentItem',
	# 'WFRichTextContentItem',
	# 'WFURLContentItem',
	# 'WFWorkflowPickerParameter',
	# 'WFWorkflowReference',
	
	
	'NSDate': 'date',
	'NSDictionary': 'keyed_list',
	#'NSMeasurement', # TO DO: unit types
	'NSNumber': 'number',
	'NSString': 'string',
	'NSURL': 'URL',
	
	'PHAsset': 'photo',
	
	'com.adobe.pdf': 'PDF',
	'com.apple.m4a-audio': 'M4A_audio',
	'com.apple.quicktime-movie': 'QuickTime_movie',
	'com.compuserve.gif': 'gif_image',
	'public.data': 'data',
	'public.html': 'HTML',
	'public.mpeg-4': 'MPEG_4',
}

prefixes = ['AV', 'CL', 'EK', 'EN', 'IN', 'MK', 'MP', 'NS', 'REM', 'WF', 'UI']
kPrefixes = re.compile(r'\A('+ '|'.join(prefixes) + ')')

kSuffixes = re.compile(r'(ContentItem|Parameter)\Z')


def snake(s): # replace spaces with underscores; used to convert action names and param labels
	return '_'.join(s.lower().split()) if s else ''

def toidentifier(s): # convert CamelCase to snake_case; used to convert input/output/param types
	if not s: return s
	t = stdtypes.get(s)
	if t: return t
	s = kSuffixes.sub('', kPrefixes.sub('', s))
	res = ''
	while s:
		c = s[0]
		s = s[1:]
		if res and c.isupper() and s and s[0].islower():
			res += '_' + c
		else:
			res += c
	# TO DO: single-quote if needed (e.g. "is.workflow.actions.addnewreminder" has badly labeled '2:00 PM' field, and some tags contain non-identifier chars)
	return res.lower()



def iotype(d):
	#d.get('Types', []): types.add(t)
	types = d.get('Types', [])
	if types:
		t = ' OR '.join(toidentifier(s) for s in types)
		if len(types) > 1:
			t = '({})'.format(t)
		if d.get('Multiple', False):
			t = 'ordered_list of: {}'.format(t)
	else:
		t = 'nothing'
	n = d.get('OutputName', '')
	if n: t += ' «{}»'.format(n)
	return t


def paramtype(p):
	t = p['Class']
	if t == 'WFNumberFieldParameter':
		t = 'number' if p.get('AllowsDecimalNumbers') else 'integer'
	elif t == 'WFEnumerationParameter':
		t = 'choice [{}]'.format(', '.join('“{}”'.format(v) for v in p.get('Items')))
	else:
		t = toidentifier(t)
	dv = p.get('DefaultValue')
	if dv:
		t = 'optional {} default {}'.format(t, dv if isinstance(dv, (bool, int, float)) else '“{}”'.format(dv))
	# TO DO: 'DisallowedVariableTypes'
	return t
	

def pm(p):
	label = snake(p.get('Label', ''))
	key = toidentifier(p['Key'])
	return '{}{} as {}'.format('{}: '.format(label) if label else '', key, paramtype(p))
	


def readDict(f, d):
	res = []
	for k, v in d.items():
		name = v.get('Name')
		if not name: continue
		ps = []
		input, output = v.get('Input', {}), v.get('Output', {})
		i, o = ('passthru', 'passthru') if v.get('InputPassthrough', False) or v.get('SnappingPassthrough', False) else (iotype(input), iotype(output))
		if i != 'nothing':
			ps.insert(0, 'action_input as {}'.format(i))
		for p in v.get('Parameters', []):
			d = p.get('Description')
			ps.append(pm(p) + (' «{}»'.format(d) if d else ''))
			#types.add(p['Class'])
		params = ''.join('\n\t\t{}'.format(p) for p in ps)
		desc = v.get('Description', {}).get('DescriptionSummary')
		dr = v.get('DescriptionResult')
		if desc and dr: 
			desc += ': ' + dr
		elif dr:
			desc = dr
		note = v.get('Description', {}).get('DescriptionNote')
		tags = ', '.join('#{}'.format(toidentifier(s)) for s in v.get('ActionKeywords', []))
		res.append('shortcut_action {} {{{}{}}} returning {} requires {{{}\n\tid: “{}”\n\tcategory: “{}”\n\ttags: [{}]\n}}'.format(snake(name), ' «{}»'.format(desc) if desc else '', params, o, '\n\t«{}»'.format(note) if note else '', k, '/'.join(s for s in [v.get('Category', ''), v.get('Subcategory', '')] if s), tags))
	return res



basepath = os.path.expanduser('~/shortcuts')


def cvt(relpath):
	p = os.path.join(basepath, relpath)
	with open(p, 'rb') as f:
		d = load(f)
	#with open(os.path.join(basepath, os.path.basename(p)+'.2.txt'), 'w', encoding='utf-8') as f:
	r = readDict(f, d)
	for i in r:
		print(i)
		print()



cvt('WorkflowKit.framework/Versions/A/Resources/WFActions.plist')

#pprint(sorted(types))

#cvt('testshortcuts/Intents.intentdefinition')

#cvt('BrowseTopNews.shortcut')

#cvt('My Fancy Shortcut.shortcut')


