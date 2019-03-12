%{
# my newest table
->kidneys.GlomSectioning
-----
glom_features_path:varchar(150)
centers:longblob
%}

classdef GlomFeatures < dj.Imported

	methods(Access=protected)

		function makeTuples(self, key)
            net=alexnet;
            sz = net.Layers(1).InputSize;
            load prepath.mat large_storage_path
            Prepath=large_storage_path;
            image_path=fetch1(kidneys.Images&key,'image_path');
            I=imread([Prepath,image_path]);
            isz=size(I);
            jumpsz=200;
            cc=fetch1(kidneys.GlomSectioning&key,'roi_props');
            area=[cc.Area];
            centers={cc.Centroid};
            centers=centers(area>35);
            glom_features=zeros(length(centers),4096);
            C=zeros(length(centers),2);
            for i=1:length(centers)
                features=[];
                center=centers{i};
                ci=center(2);
                ci=round(ci-1);
                ci=ci*20;
                ci=ci+115;
                cj=center(1);
                cj=round(cj-1);
                cj=cj*20;
                cj=cj+115;
                if (ci-200)<115
                    lowi=115;
                else
                    lowi=ci-200;
                end
                if (ci+200)>(isz(1)-115)
                    highi=(isz(1)-115);
                else
                    highi=ci+200;
                end
                if (cj-200)<115
                    lowj=115;
                else
                    lowj=cj-200;
                end
                if (cj+200)>(isz(2)-115)
                    highj=(isz(2)-115);
                else
                    highj=cj+200;
                end
                
                for y=lowi:jumpsz:highi
                    for x=lowj:jumpsz:highj
                        curr_patch = I(y + (1:sz(1)) - 114, x + (1:sz(2)) - 114, :);                        
                        features =[features;activations(net, curr_patch,...
                            'fc6','ExecutionEnvironment','cpu')]; %#ok<AGROW>
                    end
                end
                C(i,:)=[ci,cj];
                glom_features(i,:)=mean(features);
            end
            glom_features_path=sprintf('KidneyDNN/TrainingFeatures/%s_%s_glom',...
                key.image_id,key.analysis_group);
            save([Prepath,glom_features_path],'glom_features')
            key.glom_features_path=glom_features_path;
            key.centers=C;
			 self.insert(key)
		end
	end

end