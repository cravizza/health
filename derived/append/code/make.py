import os

def main():
	# Run code
	os.system('python beneficiaries.py')
	os.system('python dictionaries.py')
	os.system('python pbonificadas.py')
	os.system('python solicitudges.py')
	os.system('python cotizacion.py')
	os.system('python hdischarge.py')
	os.system('python caec.py')
	os.system('python contracts.py')

	# Logging
	filenames = [os.path.join(path, f) for path, sd, files in os.walk('../output') for f in files if 'log_' in f]
	with open('../output/log.txt', 'w') as outfile:
	    outfile.write('Logging: ' + str(os.getcwd())[38:])
	    for fname in filenames:
	        with open(fname) as infile:
	            outfile.write('\n\n\n\n' + infile.read())
	        os.remove(fname)

if __name__ == '__main__':
    main()
