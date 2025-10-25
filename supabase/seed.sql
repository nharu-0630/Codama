-- insert into public.areas (name) values ('鶴見区'), ('神奈川区'), ('西区'), ('中区'), ('南区'), ('保土ケ谷区'), ('磯子区'), ('金沢区'), ('港北区'), ('戸塚区'), ('港南区'), ('旭区'), ('緑区'), ('瀬谷区'), ('栄区'), ('泉区'), ('青葉区'), ('都筑区');
insert into public.areas (name) values ('中区');

insert into public.prompts (prompt, area_id) values ('横浜市中区に関する以下のつぶやきに対して適切な返信を100文字以内で返してください。', (select id from public.areas where name = '中区'));
