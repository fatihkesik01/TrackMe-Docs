# TrackMe Product Bible

Bu belge TrackMe'nin urun anayasasidir. Yeni ozellikler, mimari kararlar ve UX kararlarinda varsayilan referans olarak kullanilir.

## Temel Urun Ilkesi

TrackMe'nin onceligi trainer-athlete coaching deneyimidir. Social, AI, gym ve reklam ozellikleri core coaching deneyimini guclendirdigi olcude degerlidir.

## Role Sistemi

- Her kullanici potansiyel trainer olabilir.
- Athlete ve trainer ayni kullanicida bulunabilir.
- `user.role` baslangic veya kimlik baglami olabilir.
- UI mode / preferred role, kullanicinin uygulamayi o anda hangi baglamda kullandigini temsil eder.
- Trainer profile gerekiyorsa lazy olusturulabilir.
- Athlete profile creation ayri urun karariyla yonetilir.

## Program Sistemi

- Program, TrackMe'nin ana domain nesnesidir.
- Program athlete tarafindan self-guided kullanilabilir.
- Program trainer tarafindan athlete'e atanabilir.
- Programlar active, inactive, locked gibi durumlara sahip olabilir.
- Kopyalanan program kullanici tarafindan kullanilabilir.
- Kopyalanan program trainer tarafindan ogrencilerine atanabilir.

## Program Builder

- Program gunlerden olusur.
- Gunler egzersizlerden olusur.
- Egzersizlerde set, tekrar, hedef agirlik, RPE, rest, not ve ileride video/ses icerikleri bulunabilir.
- Programlara video eklenebilir.

## Template Sistemi

- Template'ler program olusturmayi hizlandirir.
- Template'ler trainer odaklidir.
- Day template ve program template desteklenir.
- Template programlara uygulaninca icerik kopyalanir; eski programlar template degisiminden otomatik etkilenmez.

## Public Program Sistemi

- Public programlar gercekten publictir.
- Public programlar kesfedilebilir.
- Public programlar kopyalanabilir.
- Kullanici kopyaladigi programi kendi programi olarak kullanabilir.
- Trainer kopyaladigi public programi athlete'lerine atayabilir.
- Public program kopyalandiginda bagimsiz bir program kopyasi olusur.
- Orijinal public program daha sonra guncellenirse mevcut kopyalar otomatik degismez.
- Kopyalanan program, kaynak programa referans tutan bir "Program Fork" olarak ele alinmalidir.
- Gelecekte kullanici isterse kaynak programdan guncellemeleri alma secenegi eklenebilir.
- Marketplace su an planlanmamaktadir.

## Media Sistemi

- Video, fotograf ve ses icerikleri desteklenecektir.
- Media sadece mesajlasma eki degildir.
- Media bir program, egzersiz, session, PR, progress photo, profile, feedback veya gym feed item ile iliskili olabilir.
- Medya dosyalari DB icinde saklanmamalidir.
- Ortak `MediaAsset` mimarisi kullanilmalidir.
- Production icin object storage + CDN tercih edilmelidir.
- Kullanici avatar fotografi `MediaAsset` uzerinden yonetilmelidir.
- Kullanici cover fotografi `MediaAsset` uzerinden yonetilmelidir.
- Media roadmap sirasi: avatar photo, cover photo, progress photos, exercise videos, program videos, athlete submission videos, trainer feedback videos, audio feedback.
- Medya icerikleri raporlanabilir olmalidir.
- Admin, raporlanan medya iceriklerini inceleyip moderation karari verebilmelidir.
- MediaAsset icinde lifecycle status'a ek olarak moderation status dusunulmelidir.

## Profile Sistemi

- Her kullanicinin avatar photo alani olacaktir.
- Her kullanicinin cover photo alani olacaktir.
- Avatar ve cover photo ayni MediaAsset altyapisini kullanir.
- Profil gorselleri gelecekte trainer portfolio, public profile ve gym context'lerinde yeniden kullanilabilir olmalidir.
- Varsayilan profil gorseli yoksa guvenli fallback avatar/cover davranisi tanimlanmalidir.

## Progress Photo Sistemi

- Athlete progress fotografi yukleyebilir.
- Gorunurluk kullanici tarafindan belirlenir.
- Trainer kendi sporcusunun paylastigi progress fotograflarini gorebilir.
- Varsayilan gizlilik guvenli olmalidir: private veya coach-only.
- Progress photos timeline gorunumunde listelenmelidir.
- Before/after karsilastirmasi desteklenmelidir.
- Athlete, her progress photo icin gorunurlugu belirleyebilmelidir.
- Trainer yalnizca kendisiyle paylasilan veya public olan progress fotograflarini gorebilmelidir.

## Video Sistemi

- Trainer feedback videosu olabilir.
- Athlete submission videosu olabilir.
- PR dogrulama videosu olabilir.
- Egzersizlere demo video eklenebilir.
- Programlara aciklayici video eklenebilir.
- Video upload mobil uygulama icin optimize edilmelidir.
- Egzersiz videolari sadece admin tarafindan yuklenen official iceriklerle sinirli degildir.
- Kullanici kendi olusturdugu egzersizlere video yukleyebilir.
- Trainer kendi programlarindaki egzersizlere video ekleyebilir.
- Ileride official/community video ayrimi desteklenebilir.

## Sesli Icerik

- Sesli feedback desteklenecektir.
- Sesli notlar program, egzersiz, session, feedback veya mesajla iliskilendirilebilir.
- Ses icerikleri de MediaAsset sistemi uzerinden yonetilmelidir.

## Media Reporting ve Moderation

- Kullanici medya iceriklerini raporlayabilir.
- Rapor nedeni, raporlayan kullanici, hedef media asset ve zaman bilgisi saklanmalidir.
- Admin raporlari inceleyip approve, reject, remove, hide veya escalate gibi kararlar verebilmelidir.
- Raporlanan medya varsayilan olarak otomatik silinmemelidir; moderation karari gerekir.
- Public veya community alanlarda gorunen medya icin moderation sureci urun guvenliginin parcasidir.
- Private coaching iceriklerinde de abuse reporting desteklenmelidir.

## Gym Sistemi

- Multi-gym desteklenecektir.
- Kullanici birden fazla gym'e uye olabilir.
- Gym uyeleri ve gym antrenorleri ayristirilabilir.
- Gym feed olabilir.
- Gym leaderboard olabilir.

## Leaderboard Sistemi

- Leaderboard gym bazli olabilir.
- Leaderboard global olabilir.
- PR evidence videosu dogrulama icin kullanilabilir.
- Leaderboard hesaplamalari transactional veri yerine derived/computed data olarak ele alinmalidir.

## AI Sistemi

- AI gelecekte olacaktir.
- AI cekirdek ozellik degildir.
- AI once assistant/draft uretici olarak konumlandirilmalidir.
- AI program generation icin program modelinin standartlasmasi gerekir.

## Mobil

- Mobil uygulama gelecekte kesin yapilacaktir.
- Workout Mode, media upload, push notification ve camera workflows mobil oncelikli dusunulmelidir.

## Reklam

- Reklam gelecekte degerlendirilebilir.
- Workout Mode ve hassas coaching feedback akislari reklam icin uygun degildir.
- Reklam daha cok feed, discovery, dashboard veya public icerik alanlarinda dusunulmelidir.
