function Data = mountHYSCOREdata(FileNames)


File = FileNames{1};
[x,y,BrukerParameters] = eprload(File);
ExtractedData = eprload(File);

[Dimension1,Dimension2] = size(ExtractedData);

TimeStep1 = BrukerParameters.XWID/(BrukerParameters.XPTS - 1)/1000;
TimeStep2 = BrukerParameters.YWID/(BrukerParameters.YPTS - 1)/1000;


%Check for folded tau-dimensions
if Dimension1 ~= Dimension2
  %Make default that second dimension is the largest 
  if Dimension1 > Dimension2
    ExtractedData = ExtractedData';
    [Dimension1,Dimension2] = size(ExtractedData);
  end
  FoldingFactor = Dimension2/Dimension1;
  TauSignals = zeros(FoldingFactor,Dimension1,Dimension1);
  StartPosition = 1;
  %Extract the additional dimension from the folded dimension    
  for FoldingIndex=1:FoldingFactor
  TauSignals(FoldingIndex,:,:)=ExtractedData(1:end,StartPosition:Dimension2/FoldingFactor*FoldingIndex);
  StartPosition = Dimension2/FoldingFactor*FoldingIndex + 1;
  end
else
  TauSignals(1,:,:) = ExtractedData;
end


%Extract the PulseSpel code for the experiment
PulseSpelProgram = BrukerParameters.PlsSPELPrgTxt;
%Identify the tau definition lines
TauDefinitionIndexes = strfind(PulseSpelProgram,'d1=');
%Extract the tau-values
for i=1:length(TauDefinitionIndexes)
    Shift = 3;
    while ~isspace(PulseSpelProgram(TauDefinitionIndexes(i) + Shift))
          TauString(Shift - 2) =  PulseSpelProgram(TauDefinitionIndexes(i) + Shift);
          Shift = Shift + 1;
    end
    TauValues(i)  = str2double(TauString);
end

Data.TauSignals = TauSignals;
Data.TauValues = TauValues;
Data.BrukerParameters = BrukerParameters;
Data.TimeStep1 = TimeStep1;
Data.TimeStep2 = TimeStep2;
Data.NUSflag = false;
end