; © FanaticGuru, https://www.autohotkey.com/boards/viewtopic.php?p=517988#p517988
; © Bart Uliasz, https://github.com/buliasz/AHKv2-Gdip
; © yakunins, https://github.com/yakunins

; Selected GDIp library functions converted to a class
Class GDIp {
	static Startup() {
		if (this.HasProp("Token"))
			return
		this.gdipModule := DllCall("LoadLibrary", "Str", "Gdiplus.dll")
		input := Buffer((A_PtrSize = 8) ? 24 : 16, 0)
		NumPut("UInt", 1, input)
		DllCall("gdiplus\GdiplusStartup", "UPtr*", &pToken := 0, "UPtr", input.ptr, "UPtr", 0)
		this.Token := pToken
	}
	static Shutdown() {
		if (this.HasProp("Token"))
			DllCall("Gdiplus\GdiplusShutdown", "UPtr", this.DeleteProp("Token"))
		DllCall("FreeLibrary", "Ptr", this.gdipModule)
	}
	static BitmapFromScreen(Area?) {
		Area := Area ?? { X: 0, Y: 0, W: A_ScreenWidth, H: A_ScreenHeight }
		chdc := this.CreateCompatibleDC()
		hbm := this.CreateDIBSection(Area.W, Area.H, chdc)
		obm := this.SelectObject(chdc, hbm)
		hhdc := this.GetDC()
		this.BitBlt(chdc, 0, 0, Area.W, Area.H, hhdc, Area.X, Area.Y)
		this.ReleaseDC(hhdc)
		pBitmap := this.CreateBitmapFromHBITMAP(hbm)
		this.SelectObject(chdc, obm), this.DeleteObject(hbm), this.DeleteDC(hhdc), this.DeleteDC(chdc)
		return pBitmap
	}
	static CreateCompatibleDC(hdc := 0) => DllCall("CreateCompatibleDC", "UPtr", hdc)
	static CreateDIBSection(w, h, hdc := "", bpp := 32, &ppvBits := 0, Usage := 0, hSection := 0, Offset := 0) {
		hdc2 := hdc ? hdc : this.GetDC()
		bi := Buffer(40, 0)
		NumPut("UInt", 40, bi, 0)
		NumPut("UInt", w, bi, 4)
		NumPut("UInt", h, bi, 8)
		NumPut("UShort", 1, bi, 12)
		NumPut("UShort", bpp, bi, 14)
		NumPut("UInt", 0, bi, 16)

		hbm := DllCall("CreateDIBSection"
			, "UPtr", hdc2
			, "UPtr", bi.ptr    ; BITMAPINFO
			, "uint", Usage
			, "UPtr*", &ppvBits
			, "UPtr", hSection
			, "uint", Offset, "UPtr")

		if !hdc
			this.ReleaseDC(hdc2)
		return hbm
	}
	static SelectObject(hdc, hgdiobj) => DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)
	static BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, raster := "") {
		return DllCall("gdi32\BitBlt"
			, "UPtr", ddc
			, "int", dx, "int", dy
			, "int", dw, "int", dh
			, "UPtr", sdc
			, "int", sx, "int", sy
			, "uint", raster ? raster : 0x00CC0020)
	}
	static CreateBitmapFromHBITMAP(hBitmap, hPalette := 0) {
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "UPtr", hBitmap, "UPtr", hPalette, "UPtr*", &pBitmap := 0)
		return pBitmap
	}
	static CreateHBITMAPFromBitmap(pBitmap, Background := 0xffffffff) {
		DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "UPtr", pBitmap, "UPtr*", &hBitmap := 0, "int", Background)
		return hBitmap
	}
	static DeleteObject(hObject) => DllCall("DeleteObject", "UPtr", hObject)
	static ReleaseDC(hdc, hwnd := 0) => DllCall("ReleaseDC", "UPtr", hwnd, "UPtr", hdc)
	static DeleteDC(hdc) => DllCall("DeleteDC", "UPtr", hdc)
	static DeleteGraphics(pGraphics) => DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
	static DisposeImage(pBitmap, noErr := 0) {
		if (StrLen(pBitmap) <= 2 && noErr = 1)
			return 0

		r := DllCall("gdiplus\GdipDisposeImage", "UPtr", pBitmap)
		if (r = 2 || r = 1) && (noErr = 1)
			r := 0
		return r
	}
	static DisposeImageAttributes(ImageAttr) => DllCall("gdiplus\GdipDisposeImageAttributes", "UPtr", ImageAttr)
	static GetDC(hwnd := 0) => DllCall("GetDC", "UPtr", hwnd)
	static GetDCEx(hwnd, flags := 0, hrgnClip := 0) => DllCall("GetDCEx", "UPtr", hwnd, "UPtr", hrgnClip, "int", flags)
	static GetImageWidth(pBitmap) {
		DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "uint*", &Width := 0)
		return Width
	}
	static GetImageHeight(pBitmap) {
		DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "uint*", &Height := 0)
		return Height
	}
	static SetInterpolationMode(pGraphics, InterpolationMode) => DllCall("gdiplus\GdipSetInterpolationMode", "UPtr", pGraphics, "Int", InterpolationMode)
	static SaveBitmapToFile(pBitmap, sOutput, Quality := 75, toBase64 := 0) {
		_p := 0

		SplitPath sOutput, , , &Extension
		if !RegExMatch(Extension, "^(?i:BMP|DIB|RLE|JPG|JPEG|JPE|JFIF|GIF|TIF|TIFF|PNG)$")
			return -1

		Extension := "." Extension
		DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &nCount := 0, "uint*", &nSize := 0)
		ci := Buffer(nSize)
		DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "UPtr", ci.ptr)
		if !(nCount && nSize)
			return -2

		static IsUnicode := StrLen(Chr(0xFFFF))
		if (IsUnicode) {
			StrGet_Name := "StrGet"
			loop nCount {
				sString := %StrGet_Name%(NumGet(ci, (idx := (48 + 7 * A_PtrSize) * (A_Index - 1)) + 32 + 3 * A_PtrSize, "UPtr"), "UTF-16")
				if !InStr(sString, "*" Extension)
					continue

				pCodec := ci.ptr + idx
				break
			}
		} else {
			loop nCount {
				Location := NumGet(ci, 76 * (A_Index - 1) + 44, "UPtr")
				nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int", 0, "uint", 0, "uint", 0)
				sString := Buffer(nSize)
				DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
				if !InStr(sString, "*" Extension)
					continue

				pCodec := ci.ptr + 76 * (A_Index - 1)
				break
			}
		}

		if !pCodec
			return -3

		if (Quality != 75) {
			Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
			if (Quality > 90 && toBase64 = 1)
				Quality := 90

			if RegExMatch(Extension, "^\.(?i:JPG|JPEG|JPE|JFIF)$") {
				DllCall("gdiplus\GdipGetEncoderParameterListSize", "UPtr", pBitmap, "UPtr", pCodec, "uint*", &nSize)
				EncoderParameters := Buffer(nSize, 0)
				DllCall("gdiplus\GdipGetEncoderParameterList", "UPtr", pBitmap, "UPtr", pCodec, "uint", nSize, "UPtr", EncoderParameters.ptr)
				nCount := NumGet(EncoderParameters, "UInt")
				loop nCount {
					elem := (24 + A_PtrSize) * (A_Index - 1) + 4 + (pad := (A_PtrSize = 8) ? 4 : 0)
					if (NumGet(EncoderParameters, elem + 16, "UInt") = 1) && (NumGet(EncoderParameters, elem + 20, "UInt") = 6) {
						_p := elem + EncoderParameters.ptr - pad - 4
						NumPut(Quality, NumGet(NumPut(4, NumPut(1, _p + 0, "UPtr") + 20, "UInt"), "UPtr"), "UInt")
						break
					}
				}
			}
		}

		if (toBase64 = 1) {
			; part of the function extracted from ImagePut by iseahound, https://www.autohotkey.com/boards/viewtopic.php?f=6&t=76301&sid=bfb7c648736849c3c53f08ea6b0b1309
			DllCall("ole32\CreateStreamOnHGlobal", "UPtr", 0, "int", true, "UPtr*", &pStream := 0)
			_E := DllCall("gdiplus\GdipSaveImageToStream", "UPtr", pBitmap, "UPtr", pStream, "UPtr", pCodec, "uint", _p)
			if _E
				return -6

			DllCall("ole32\GetHGlobalFromStream", "UPtr", pStream, "uint*", &hData)
			pData := DllCall("GlobalLock", "UPtr", hData, "UPtr")
			nSize := DllCall("GlobalSize", "uint", pData)

			bin := Buffer(nSize, 0)
			DllCall("RtlMoveMemory", "UPtr", bin.ptr, "UPtr", pData, "uptr", nSize)
			DllCall("GlobalUnlock", "UPtr", hData)
			ObjRelease(pStream)
			DllCall("GlobalFree", "UPtr", hData)

			; Using CryptBinaryToStringA saves about 2MB in memory.
			DllCall("Crypt32.dll\CryptBinaryToStringA", "UPtr", bin.ptr, "uint", nSize, "uint", 0x40000001, "UPtr", 0, "uint*", &base64Length := 0)
			base64 := Buffer(base64Length, 0)
			_E := DllCall("Crypt32.dll\CryptBinaryToStringA", "UPtr", bin.ptr, "uint", nSize, "uint", 0x40000001, "UPtr", &base64, "uint*", base64Length)
			if !_E
				return -7

			bin := Buffer(0)
			return StrGet(base64, base64Length, "CP0")
		}

		_E := DllCall("gdiplus\GdipSaveImageToFile", "UPtr", pBitmap, "WStr", sOutput, "UPtr", pCodec, "uint", _p)
		return _E ? -5 : 0
	}
	static CreateBitmap(Width, Height, Format := 0x26200A) {
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", Width, "Int", Height, "Int", 0, "Int", Format, "UPtr", 0, "UPtr*", &pBitmap := 0)
		return pBitmap
	}
	static PixelateBitmap(pBitmap, &pBitmapOut, BlockSize) {
		static PixelateBitmap := ""

		if (!PixelateBitmap) {
			if A_PtrSize != 8 ; x86 machine code
				MCode_PixelateBitmap := "
				(LTrim Join
				558BEC83EC3C8B4514538B5D1C99F7FB56578BC88955EC894DD885C90F8E830200008B451099F7FB8365DC008365E000894DC88955F08945E833FF897DD4
				397DE80F8E160100008BCB0FAFCB894DCC33C08945F88945FC89451C8945143BD87E608B45088D50028BC82BCA8BF02BF2418945F48B45E02955F4894DC4
				8D0CB80FAFCB03CA895DD08BD1895DE40FB64416030145140FB60201451C8B45C40FB604100145FC8B45F40FB604020145F883C204FF4DE475D6034D18FF
				4DD075C98B4DCC8B451499F7F98945148B451C99F7F989451C8B45FC99F7F98945FC8B45F899F7F98945F885DB7E648B450C8D50028BC82BCA83C103894D
				C48BC82BCA41894DF48B4DD48945E48B45E02955E48D0C880FAFCB03CA895DD08BD18BF38A45148B7DC48804178A451C8B7DF488028A45FC8804178A45F8
				8B7DE488043A83C2044E75DA034D18FF4DD075CE8B4DCC8B7DD447897DD43B7DE80F8CF2FEFFFF837DF0000F842C01000033C08945F88945FC89451C8945
				148945E43BD87E65837DF0007E578B4DDC034DE48B75E80FAF4D180FAFF38B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945CC0F
				B6440E030145140FB60101451C0FB6440F010145FC8B45F40FB604010145F883C104FF4DCC75D8FF45E4395DE47C9B8B4DF00FAFCB85C9740B8B451499F7
				F9894514EB048365140033F63BCE740B8B451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB
				038975F88975E43BDE7E5A837DF0007E4C8B4DDC034DE48B75E80FAF4D180FAFF38B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955CC8A55
				1488540E038A551C88118A55FC88540F018A55F888140183C104FF4DCC75DFFF45E4395DE47CA68B45180145E0015DDCFF4DC80F8594FDFFFF8B451099F7
				FB8955F08945E885C00F8E450100008B45EC0FAFC38365DC008945D48B45E88945CC33C08945F88945FC89451C8945148945103945EC7E6085DB7E518B4D
				D88B45080FAFCB034D108D50020FAF4D18034DDC8BF08BF88945F403CA2BF22BFA2955F4895DC80FB6440E030145140FB60101451C0FB6440F010145FC8B
				45F40FB604080145F883C104FF4DC875D8FF45108B45103B45EC7CA08B4DD485C9740B8B451499F7F9894514EB048365140033F63BCE740B8B451C99F7F9
				89451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975103975EC7E5585DB7E468B4DD88B450C
				0FAFCB034D108D50020FAF4D18034DDC8BF08BF803CA2BF22BFA2BC2895DC88A551488540E038A551C88118A55FC88540F018A55F888140183C104FF4DC8
				75DFFF45108B45103B45EC7CAB8BC3C1E0020145DCFF4DCC0F85CEFEFFFF8B4DEC33C08945F88945FC89451C8945148945103BC87E6C3945F07E5C8B4DD8
				8B75E80FAFCB034D100FAFF30FAF4D188B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945C80FB6440E030145140FB60101451C0F
				B6440F010145FC8B45F40FB604010145F883C104FF4DC875D833C0FF45108B4DEC394D107C940FAF4DF03BC874068B451499F7F933F68945143BCE740B8B
				451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975083975EC7E63EB0233F639
				75F07E4F8B4DD88B75E80FAFCB034D080FAFF30FAF4D188B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955108A551488540E038A551C8811
				8A55FC88540F018A55F888140883C104FF4D1075DFFF45088B45083B45EC7C9F5F5E33C05BC9C21800
				)"
			else ; x64 machine code
				MCode_PixelateBitmap := "
				(LTrim Join
				4489442418488954241048894C24085355565741544155415641574883EC28418BC1448B8C24980000004C8BDA99488BD941F7F9448BD0448BFA8954240C
				448994248800000085C00F8E9D020000418BC04533E4458BF299448924244C8954241041F7F933C9898C24980000008BEA89542404448BE889442408EB05
				4C8B5C24784585ED0F8E1A010000458BF1418BFD48897C2418450FAFF14533D233F633ED4533E44533ED4585C97E5B4C63BC2490000000418D040A410FAF
				C148984C8D441802498BD9498BD04D8BD90FB642010FB64AFF4403E80FB60203E90FB64AFE4883C2044403E003F149FFCB75DE4D03C748FFCB75D0488B7C
				24188B8C24980000004C8B5C2478418BC59941F7FE448BE8418BC49941F7FE448BE08BC59941F7FE8BE88BC69941F7FE8BF04585C97E4048639C24900000
				004103CA4D8BC1410FAFC94863C94A8D541902488BCA498BC144886901448821408869FF408871FE4883C10448FFC875E84803D349FFC875DA8B8C249800
				0000488B5C24704C8B5C24784183C20448FFCF48897C24180F850AFFFFFF8B6C2404448B2424448B6C24084C8B74241085ED0F840A01000033FF33DB4533
				DB4533D24533C04585C97E53488B74247085ED7E42438D0C04418BC50FAF8C2490000000410FAFC18D04814863C8488D5431028BCD0FB642014403D00FB6
				024883C2044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC17CB28BCD410FAFC985C9740A418BC299F7F98BF0EB0233F685C9740B418BC3
				99F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585C97E4D4C8B74247885ED7E3841
				8D0C14418BC50FAF8C2490000000410FAFC18D04814863C84A8D4431028BCD40887001448818448850FF448840FE4883C00448FFC975E8FFC2413BD17CBD
				4C8B7424108B8C2498000000038C2490000000488B5C24704503E149FFCE44892424898C24980000004C897424100F859EFDFFFF448B7C240C448B842480
				000000418BC09941F7F98BE8448BEA89942498000000896C240C85C00F8E3B010000448BAC2488000000418BCF448BF5410FAFC9898C248000000033FF33
				ED33F64533DB4533D24533C04585FF7E524585C97E40418BC5410FAFC14103C00FAF84249000000003C74898488D541802498BD90FB642014403D00FB602
				4883C2044403D80FB642FB03F00FB642FA03E848FFCB75DE488B5C247041FFC0453BC77CAE85C9740B418BC299F7F9448BE0EB034533E485C9740A418BC3
				99F7F98BD8EB0233DB85C9740A8BC699F7F9448BD8EB034533DB85C9740A8BC599F7F9448BD0EB034533D24533C04585FF7E4E488B4C24784585C97E3541
				8BC5410FAFC14103C00FAF84249000000003C74898488D540802498BC144886201881A44885AFF448852FE4883C20448FFC875E941FFC0453BC77CBE8B8C
				2480000000488B5C2470418BC1C1E00203F849FFCE0F85ECFEFFFF448BAC24980000008B6C240C448BA4248800000033FF33DB4533DB4533D24533C04585
				FF7E5A488B7424704585ED7E48418BCC8BC5410FAFC94103C80FAF8C2490000000410FAFC18D04814863C8488D543102418BCD0FB642014403D00FB60248
				83C2044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC77CAB418BCF410FAFCD85C9740A418BC299F7F98BF0EB0233F685C9740B418BC399
				F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585FF7E4E4585ED7E42418BCC8BC541
				0FAFC903CA0FAF8C2490000000410FAFC18D04814863C8488B442478488D440102418BCD40887001448818448850FF448840FE4883C00448FFC975E8FFC2
				413BD77CB233C04883C428415F415E415D415C5F5E5D5BC3
				)"

			PixelateBitmap := Buffer(StrLen(MCode_PixelateBitmap) // 2)
			nCount := StrLen(MCode_PixelateBitmap) // 2
			loop nCount {
				NumPut("UChar", "0x" SubStr(MCode_PixelateBitmap, (2 * A_Index) - 1, 2), PixelateBitmap, A_Index - 1)
			}
			DllCall("VirtualProtect", "UPtr", PixelateBitmap.Ptr, "UPtr", PixelateBitmap.Size, "UInt", 0x40, "UPtr*", 0)
		}

		Width := this.GetImageWidth(pBitmap)
		Height := this.GetImageHeight(pBitmap)

		if (Width != this.GetImageWidth(pBitmapOut) || Height != this.GetImageHeight(pBitmapOut))
			return -1
		if (BlockSize > Width || BlockSize > Height)
			return -2

		E1 := this.LockBits(pBitmap, 0, 0, Width, Height, &Stride1 := "", &Scan01 := "", &BitmapData1 := "")
		E2 := this.LockBits(pBitmapOut, 0, 0, Width, Height, &Stride2 := "", &Scan02 := "", &BitmapData2 := "")
		if (E1 || E2)
			return -3

		DllCall(PixelateBitmap.Ptr, "UPtr", Scan01, "UPtr", Scan02, "Int", Width, "Int", Height, "Int", Stride1, "Int", BlockSize)
		this.UnlockBits(pBitmap, &BitmapData1)
		this.UnlockBits(pBitmapOut, &BitmapData2)
		return 0
	}
	static LockBits(pBitmap, x, y, w, h, &Stride, &Scan0, &BitmapData, LockMode := 3, PixelFormat := 0x26200a) {
		this.CreateRect(&_Rect := "", x, y, w, h)
		BitmapData := Buffer(16 + 2 * (A_PtrSize ? A_PtrSize : 4), 0)
		_E := DllCall("Gdiplus\GdipBitmapLockBits", "UPtr", pBitmap, "UPtr", _Rect.Ptr, "UInt", LockMode, "Int", PixelFormat, "UPtr", BitmapData.Ptr)
		Stride := NumGet(BitmapData, 8, "Int")
		Scan0 := NumGet(BitmapData, 16, "UPtr")
		return _E
	}
	static UnlockBits(pBitmap, &BitmapData) {
		return DllCall("Gdiplus\GdipBitmapUnlockBits", "UPtr", pBitmap, "UPtr", BitmapData.Ptr)
	}
	static CreateRect(&Rect, x, y, w, h) {
		Rect := Buffer(16)
		NumPut("UInt", x, "UInt", y, "UInt", w, "UInt", h, Rect)
	}
	static ScaleBitmap(pBitmap, scale := 1) {
		w := this.GetImageWidth(pBitmap) * scale
		h := this.GetImageHeight(pBitmap) * scale
		result := this.CreateBitmap(w, h)

		G2 := this.GraphicsFromImage(result)
		;this.SetSmoothingMode(G2, 4)
		;this.SetInterpolationMode(G2, 7)
		this.DrawImage(G2, pBitmap, 0, 0, w, h)
		this.DeleteGraphics(G2)
		this.DisposeImage(pBitmap)
		return result
	}
	static SetSmoothingMode(pGraphics, SmoothingMode) => DllCall("gdiplus\GdipSetSmoothingMode", "UPtr", pGraphics, "Int", SmoothingMode)
	static BlurBitmap(pBitmap, blurSize := 20) {
		if (blurSize > 100 || blurSize < 1) {
			return -1
		}

		sWidth := this.GetImageWidth(pBitmap)
		sHeight := this.GetImageHeight(pBitmap)
		dWidth := sWidth // blurSize, dHeight := sHeight // blurSize

		pBitmap1 := this.CreateBitmap(dWidth, dHeight)
		G1 := this.GraphicsFromImage(pBitmap1)
		this.SetInterpolationMode(G1, 7)
		this.DrawImage(G1, pBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)
		this.DeleteGraphics(G1)

		pBitmap2 := this.CreateBitmap(sWidth, sHeight)
		G2 := this.GraphicsFromImage(pBitmap2)
		this.SetInterpolationMode(G2, 7)
		this.DrawImage(G2, pBitmap1, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight)
		this.DeleteGraphics(G2)
		this.DisposeImage(pBitmap1)

		return pBitmap2
	}
	static GraphicsFromImage(pBitmap) {
		DllCall("gdiplus\GdipGetImageGraphicsContext", "UPtr", pBitmap, "UPtr*", &pGraphics := 0)
		return pGraphics
	}
	static DrawImage(pGraphics, pBitmap, dx := "", dy := "", dw := "", dh := "", sx := "", sy := "", sw := "", sh := "", Matrix := 1) {
		if !IsNumber(Matrix)
			ImageAttr := this.SetImageAttributesColorMatrix(Matrix)
		else if (Matrix != 1)
			ImageAttr := this.SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
		else
			ImageAttr := 0

		if (sx = "" && sy = "" && sw = "" && sh = "") {
			if (dx = "" && dy = "" && dw = "" && dh = "")
			{
				sx := dx := 0, sy := dy := 0
				sw := dw := this.GetImageWidth(pBitmap)
				sh := dh := this.GetImageHeight(pBitmap)
			} else {
				sx := sy := 0
				sw := this.GetImageWidth(pBitmap)
				sh := this.GetImageHeight(pBitmap)
			}
		}

		_E := DllCall("gdiplus\GdipDrawImageRectRect"
			, "UPtr", pGraphics
			, "UPtr", pBitmap
			, "Float", dx
			, "Float", dy
			, "Float", dw
			, "Float", dh
			, "Float", sx
			, "Float", sy
			, "Float", sw
			, "Float", sh
			, "Int", 2
			, "UPtr", ImageAttr
			, "UPtr", 0
			, "UPtr", 0)
		if ImageAttr
			this.DisposeImageAttributes(ImageAttr)
		return _E
	}
	static SetImageAttributesColorMatrix(Matrix) {
		ColourMatrix := Buffer(100, 0)
		Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", , 1), "[^\d-\.]+", "|")
		Matrix := StrSplit(Matrix, "|")

		loop 25 {
			M := (Matrix[A_Index] != "") ? Matrix[A_Index] : Mod(A_Index - 1, 6) ? 0 : 1
			NumPut("Float", M, ColourMatrix, (A_Index - 1) * 4)
		}

		DllCall("gdiplus\GdipCreateImageAttributes", "UPtr*", &ImageAttr := 0)
		DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "UPtr", ImageAttr, "Int", 1, "Int", 1, "UPtr", ColourMatrix.Ptr, "UPtr", 0, "Int", 0)

		return ImageAttr
	}
}