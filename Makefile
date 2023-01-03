ext :=  Timer.ext
proddir := ~/.smiteworks/fgdata/extensions/
testdir := ~/.smiteworks/fgdata/channels/Test/extensions/

prod: 
	cd ./src/; zip -r ../$(ext) ./*
	mv $(ext) $(proddir)

test:
	cd ./src/ ; zip -r ../$(ext) ./*
	mv $(ext) $(testdir)
