!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.3 (r3163) - 09/25/2009 09:04
!
MODULE G_MODULE_MP_MKESSLER
  IMPLICIT NONE

CONTAINS

  SUBROUTINE G_MKESSLER(t, td, qv, qvd, qc, qcd, qr, qrd, rho, rhod, p, &
&    pd, pii, piid, dt_in, z, xlv, cp, ep2, svp1, svp2, svp3, svpt0, &
&    rhowater, dz8w, rainnc, rainncd, rainncv, rainncvd, ids, ide, jds, &
&    jde, kds, kde, ims, ime, jms, jme, kms, kme, its, ite, jts, jte, kts&
&    , kte)

    USE module_mp_mkessler, ONLY : SMALLSTEP

    IMPLICIT NONE
!----------------------------------------------------------------
! Restructered from WRF Kessler Warm rain process
! H.L. Wang Aug. 1 2009
!----------------------------------------------------------------
    REAL, PARAMETER :: c1=.001
    REAL, PARAMETER :: c2=.001
    REAL, PARAMETER :: c3=2.2
    REAL, PARAMETER :: c4=.875
!----------------------------------------------------------------
    INTEGER, INTENT(IN) :: ids, ide, jds, jde, kds, kde, ims, ime, jms, &
&    jme, kms, kme, its, ite, jts, jte, kts, kte
    REAL, INTENT(IN) :: xlv, cp
    REAL, INTENT(IN) :: ep2, svp1, svp2, svp3, svpt0
    REAL, INTENT(IN) :: rhowater
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT) :: t, qv, &
&    qc, qr
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(INOUT) :: td, qvd&
&    , qcd, qrd
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN) :: rho, p, &
&    pii, dz8w
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN) :: rhod, pd, &
&    piid
    REAL, DIMENSION(ims:ime, kms:kme, jms:jme), INTENT(IN) :: z
    REAL, INTENT(IN) :: dt_in
    REAL, DIMENSION(ims:ime, jms:jme), INTENT(INOUT) :: rainnc, rainncv
    REAL, DIMENSION(ims:ime, jms:jme), INTENT(INOUT) :: rainncd, &
&    rainncvd
! local variables
    REAL :: qrprod, ern, gam, rcgs, rcgsi
    REAL, DIMENSION(its:ite, kts:kte, jts:jte) :: prod
    REAL, DIMENSION(kts:kte) :: vt, prodk, vtden, rdzk, rhok, piik, &
&    factor, rdzw
    REAL, DIMENSION(kts:kte) :: rdzkd, rhokd, piikd
    INTEGER :: i, j, k
    INTEGER :: nfall, n, nfall_new
    REAL :: qrr, pressure, temp, es, qvs, dz, dt
    REAL :: f5, dtfall, rdz, product
    REAL :: vtmax, crmax, factorn
    REAL :: qcr, factorr, ppt
    REAL, PARAMETER :: max_cr_sedimentation=0.75
!----------------------------------------------------------------
    INTEGER :: imax, kmax
! whl
    REAL, DIMENSION(kts:kte) :: qv1d, qc1d, qr1d, t1d, p1d
    REAL, DIMENSION(kts:kte) :: qv1dd, qc1dd, qr1dd, t1dd, p1dd
    REAL :: dtleft, rainncv0, max_cr
    REAL :: rainncv0d
    INTEGER :: kvts, kvte, kn
    dt = dt_in
    f5 = svp2*(svpt0-svp3)*xlv/cp
    rdzk = 0.0
    rdzw = 0.0
    DO j=jts,jte
      DO i=its,ite
        DO k=1,kte-1
          rdzkd(k) = 0.0
          rdzk(k) = 1./(z(i, k+1, j)-z(i, k, j))
        END DO
        rdzkd(kte) = 0.0
        rdzk(kte) = 1./(z(i, kte, j)-z(i, kte-1, j))
      END DO
    END DO
    qv1dd = 0.0
    qc1dd = 0.0
    p1dd = 0.0
    qr1dd = 0.0
    piikd = 0.0
    rhokd = 0.0
    t1dd = 0.0
    DO j=jts,jte
      DO i=its,ite
        DO k=1,kte
          qv1dd(k) = qvd(i, k, j)
          qv1d(k) = qv(i, k, j)
          qc1dd(k) = qcd(i, k, j)
          qc1d(k) = qc(i, k, j)
          qr1dd(k) = qrd(i, k, j)
          qr1d(k) = qr(i, k, j)
          t1dd(k) = td(i, k, j)
          t1d(k) = t(i, k, j)
          p1dd(k) = pd(i, k, j)
          p1d(k) = p(i, k, j)
          rhokd(k) = rhod(i, k, j)
          rhok(k) = rho(i, k, j)
          piikd(k) = piid(i, k, j)
          piik(k) = pii(i, k, j)
          rdzw(k) = 1./dz8w(i, k, j)
        END DO
!   print*,i,j
        kvts = kts
        kvte = kte
        max_cr = max_cr_sedimentation
        dtleft = dt
        CALL SMALLSTEP(qr1d, rdzk, rdzw, rhok, max_cr, dtleft, nfall, &
&                 kvts, kvte)
        dtleft = dt/nfall
        rainncv0 = 0.0
        rainncvd(i, j) = 0.0
        rainncv(i, j) = 0.0
        DO kn=1,nfall
          CALL RFALL_D(qr1d, qr1dd, rdzk, rdzw, rhok, rhokd, rainncv0, &
&                 rainncv0d, rhowater, max_cr, dtleft, kvts, kvte)
          rainncvd(i, j) = rainncvd(i, j) + rainncv0d
          rainncv(i, j) = rainncv(i, j) + rainncv0
        END DO
!    print*,rainncv0
!autoca(qc1d,qr1d, kvts,kvte,c1,c2,c3,c4,dt )
        rainncd(i, j) = rainncd(i, j) + rainncvd(i, j)
        rainnc(i, j) = rainnc(i, j) + rainncv(i, j)
!autoca(qc1d,qr1d, kvts,kvte,c1,c2,c3,c4,dt )
        CALL AUTOCA_D(qc1d, qc1dd, qr1d, qr1dd, kvts, kvte, c1, c2, c3, &
&                c4, dt)
!satadj(qv,qc,qr, tmp, pii,rho,  kvts,kvte,xlv, cp,EP2,SVP1,SVP2,SVP3,SVPT0)
        CALL SATADJ_D(qv1d, qv1dd, qc1d, qc1dd, qr1d, qr1dd, t1d, t1dd, &
&                p1d, p1dd, piik, piikd, rhok, rhokd, kvts, kvte, xlv, dt&
&                , cp, ep2, svp1, svp2, svp3, svpt0)
        DO k=1,kte
          qvd(i, k, j) = qv1dd(k)
          qv(i, k, j) = qv1d(k)
          qcd(i, k, j) = qc1dd(k)
          qc(i, k, j) = qc1d(k)
          qrd(i, k, j) = qr1dd(k)
          qr(i, k, j) = qr1d(k)
          td(i, k, j) = t1dd(k)
          t(i, k, j) = t1d(k)
        END DO
      END DO
    END DO
    RETURN
  END SUBROUTINE G_MKESSLER
!
!  Differentiation of rfall in forward (tangent) mode:
!   variations  of output variables: prodk rainncv0
!   with respect to input variables: prodk rhok
  SUBROUTINE RFALL_D(prodk, prodkd, rdzk, rdzw, rhok, rhokd, rainncv0, &
&    rainncv0d, rhowat, max_cr, dtfall, kvts, kvte)
    IMPLICIT NONE
    INTEGER :: k, kvts, kvte
    REAL, DIMENSION(kvts:kvte) :: vtden, vt, prodk, factor, rdzk, rdzw, &
&    rhok
    REAL, DIMENSION(kvts:kvte) :: vtdend, vtd, prodkd, factord, rhokd
    REAL :: rainncv0, rhowat, max_cr, ppt, dtleft
    REAL :: rainncv0d, pptd
    REAL :: qrr, dtfall
    REAL :: qrrd
    REAL :: arg1
    REAL :: arg1d
    INTRINSIC SQRT
    DO k=kvts,kvte
      IF (prodk(k) .LT. 0) THEN
        prodkd(k) = 0.0
        prodk(k) = 0.0
      END IF
    END DO
    vtd = 0.0
    vtdend = 0.0
    DO k=kvts,kvte
      qrrd = 0.001*(prodkd(k)*rhok(k)+prodk(k)*rhokd(k))
      qrr = prodk(k)*0.001*rhok(k)
      arg1d = (rhokd(1)*rhok(k)-rhok(1)*rhokd(k))/rhok(k)**2
      arg1 = rhok(1)/rhok(k)
      IF (arg1 .EQ. 0.0) THEN
        vtdend(k) = 0.0
      ELSE
        vtdend(k) = arg1d/(2.0*SQRT(arg1))
      END IF
      vtden(k) = SQRT(arg1)
      IF (qrr/(0.001*rhok(k)) .GE. 1d-5) THEN
        vtd(k) = 36.34*(0.1364*qrr**(-0.8636)*qrrd*vtden(k)+qrr**0.1364*&
&          vtdend(k))
        vt(k) = 36.34*qrr**0.1364*vtden(k)
      ELSE
        vtd(k) = 0.0
        vt(k) = 0.0
      END IF
    END DO
    factord = 0.0
!     pause
    DO k=kvts,kvte-1
      factord(k) = -(dtfall*rdzk(k)*rhokd(k)/rhok(k)**2)
      factor(k) = dtfall*rdzk(k)/rhok(k)
    END DO
    factord(kvte) = 0.0
    factor(kvte) = dtfall*rdzk(kvte)
    ppt = 0.
    k = 1
    pptd = dtfall*((rhokd(k)*prodk(k)+rhok(k)*prodkd(k))*vt(k)+rhok(k)*&
&      prodk(k)*vtd(k))/rhowat
    ppt = rhok(k)*prodk(k)*vt(k)*dtfall/rhowat
!mm
    rainncv0d = 1000.*pptd
    rainncv0 = ppt*1000.
!      print*,rainncv0
!------------------------------------------------------------------------------
! Time split loop, Fallout done with flux upstream
!------------------------------------------------------------------------------
    DO k=kvts,kvte-1
      prodkd(k) = prodkd(k) - factord(k)*(rhok(k)*prodk(k)*vt(k)-rhok(k+&
&        1)*prodk(k+1)*vt(k+1)) - factor(k)*((rhokd(k)*prodk(k)+rhok(k)*&
&        prodkd(k))*vt(k)+rhok(k)*prodk(k)*vtd(k)-(rhokd(k+1)*prodk(k+1)+&
&        rhok(k+1)*prodkd(k+1))*vt(k+1)-rhok(k+1)*prodk(k+1)*vtd(k+1))
      prodk(k) = prodk(k) - factor(k)*(rhok(k)*prodk(k)*vt(k)-rhok(k+1)*&
&        prodk(k+1)*vt(k+1))
    END DO
    k = kvte
    prodkd(k) = prodkd(k) - (factord(k)*prodk(k)+factor(k)*prodkd(k))*vt&
&      (k) - factor(k)*prodk(k)*vtd(k)
    prodk(k) = prodk(k) - factor(k)*prodk(k)*vt(k)
    DO k=kvts,kvte
      IF (prodk(k) .LT. 0) THEN
        prodkd(k) = 0.0
        prodk(k) = 0.0
      END IF
    END DO
  END SUBROUTINE RFALL_D
!   with respect to input variables: qc1d qr1d
  SUBROUTINE AUTOCA_D(qc1d, qc1dd, qr1d, qr1dd, kvts, kvte, c1, c2, c3, &
&    c4, dt)
    IMPLICIT NONE
!     print*,k,qrprod
    INTEGER :: kvts, kvte, k
    REAL, DIMENSION(kvts:kvte) :: qc1d, qr1d
    REAL, DIMENSION(kvts:kvte) :: qc1dd, qr1dd
    REAL :: c1, c2, c3, c4
    REAL :: qrrc, dt, factorn, qrprod, qrprod2
    REAL :: factornd, qrprodd, qrprod2d
    REAL :: pwr1
    REAL :: pwr1d
    qrrc = 1.0e-5
    DO k=kvts,kvte
      IF (qr1d(k) .LT. 0.0) THEN
        qr1dd(k) = 0.0
        qr1d(k) = 0.0
      END IF
      IF (qc1d(k) .LT. 0.0) THEN
        qc1dd(k) = 0.0
        qc1d(k) = 0.0
      END IF
      IF (qr1d(k) .GE. qrrc) THEN
        IF (qr1d(k) .GT. 0.0 .OR. (qr1d(k) .LT. 0.0 .AND. c4 .EQ. INT(c4&
&            ))) THEN
          pwr1d = c4*qr1d(k)**(c4-1)*qr1dd(k)
        ELSE IF (qr1d(k) .EQ. 0.0 .AND. c4 .EQ. 1.0) THEN
          pwr1d = qr1dd(k)
        ELSE
          pwr1d = 0.0
        END IF
        pwr1 = qr1d(k)**c4
        factornd = -(c3*dt*pwr1d/(1.+c3*dt*pwr1)**2)
        factorn = 1.0/(1.+c3*dt*pwr1)
      ELSE
        factorn = 1.0
        factornd = 0.0
      END IF
      qrprodd = qc1dd(k)*(1.0-factorn) - qc1d(k)*factornd
      qrprod = qc1d(k)*(1.0-factorn)
      qrprod2 = 0.0
      IF (qc1d(k) - c2 .GT. 0) THEN
        qrprod2d = c1*dt*(factornd*(qc1d(k)-c2)+factorn*qc1dd(k))
        qrprod2 = factorn*c1*dt*(qc1d(k)-c2)
        IF (qrprod2 .GT. qc1d(k) - c2) THEN
          qrprod2d = qc1dd(k)
          qrprod2 = qc1d(k) - c2
        END IF
      ELSE
        qrprod2d = 0.0
      END IF
!        print*,k,qrprod2
      qrprodd = qrprodd + qrprod2d
      qrprod = qrprod + qrprod2
      IF (qc1d(k) - qrprod .GT. 0) THEN
        qc1dd(k) = qc1dd(k) - qrprodd
        qc1d(k) = qc1d(k) - qrprod
        qr1dd(k) = qr1dd(k) + qrprodd
        qr1d(k) = qr1d(k) + qrprod
      ELSE
        qc1dd(k) = 0.0
        qc1d(k) = 0.0
        qrprodd = qc1dd(k)
        qrprod = qc1d(k)
        qr1dd(k) = qr1dd(k) + qrprodd
        qr1d(k) = qr1d(k) + qrprod
      END IF
    END DO
  END SUBROUTINE AUTOCA_D
!  Differentiation of satadj in forward (tangent) mode:
!   variations  of output variables: qc qr qv tmp
!   with respect to input variables: qc qr qv p1d rhok tmp pii
  SUBROUTINE SATADJ_D(qv, qvd, qc, qcd, qr, qrd, tmp, tmpd, p1d, p1dd, &
&    pii, piid, rhok, rhokd, kvts, kvte, xlv, dt, cp, ep2, svp1, svp2, &
&    svp3, svpt0)
    IMPLICIT NONE
    INTEGER :: kvts, kvte, k
    REAL, DIMENSION(kvts:kvte) :: qv, qc, qr, tmp, p1d, pii, rhok
    REAL, DIMENSION(kvts:kvte) :: qvd, qcd, qrd, tmpd, p1dd, piid, rhokd
    REAL, DIMENSION(kvts:kvte) :: rcgs, pressure, temp, es, qvs
    REAL, DIMENSION(kvts:kvte) :: rcgsd, pressured, tempd, esd, qvsd
    REAL, DIMENSION(kvts:kvte) :: ern, qv2cl, rn2qv
    REAL, DIMENSION(kvts:kvte) :: ernd, qv2cld, rn2qvd
! local var
    REAL :: svp1, svp2, svp3, svpt0, ep2, xlv, cp, dt, f5
    REAL :: ernmax, product
    REAL :: ernmaxd, productd
    REAL :: arg1
    REAL :: arg1d
    INTRINSIC EXP
    f5 = svp2*(svpt0-svp3)*xlv/cp
    tempd = 0.0
    rcgsd = 0.0
    pressured = 0.0
    esd = 0.0
    qvsd = 0.0
    DO k=kvts,kvte
!constant
      rcgsd(k) = 0.001*rhokd(k)
      rcgs(k) = 0.001*rhok(k)
      pressured(k) = p1dd(k)
      pressure(k) = p1d(k)
      tempd(k) = piid(k)*tmp(k) + pii(k)*tmpd(k)
      temp(k) = pii(k)*tmp(k)
      arg1d = (svp2*tempd(k)*(temp(k)-svp3)-svp2*(temp(k)-svpt0)*tempd(k&
&        ))/(temp(k)-svp3)**2
      arg1 = svp2*(temp(k)-svpt0)/(temp(k)-svp3)
      esd(k) = 1000.*svp1*arg1d*EXP(arg1)
      es(k) = 1000.*svp1*EXP(arg1)
      qvsd(k) = (ep2*esd(k)*(pressure(k)-es(k))-ep2*es(k)*(pressured(k)-&
&        esd(k)))/(pressure(k)-es(k))**2
      qvs(k) = ep2*es(k)/(pressure(k)-es(k))
      IF (qr(k) .LT. 0) THEN
        qrd(k) = 0.0
        qr(k) = 0.0
      END IF
      IF (qv(k) .LT. 0) THEN
        qvd(k) = 0.0
        qv(k) = 0.0
      END IF
      IF (qc(k) .LT. 0) THEN
        qcd(k) = 0.0
        qc(k) = 0.0
      END IF
    END DO
    ernd = 0.0
    qv2cld = 0.0
    rn2qvd = 0.0
    DO k=kvts,kvte
!not related to time; maximum transform qv to cl (sat) or cl to qv (sub sat)
      qv2cld(k) = ((qvd(k)-qvsd(k))*(1.+pressure(k)/(pressure(k)-es(k))*&
&        qvs(k)*f5/(temp(k)-svp3)**2)-(qv(k)-qvs(k))*(f5*((pressured(k)*(&
&        pressure(k)-es(k))-pressure(k)*(pressured(k)-esd(k)))*qvs(k)/(&
&        pressure(k)-es(k))**2+pressure(k)*qvsd(k)/(pressure(k)-es(k)))*(&
&        temp(k)-svp3)**2-pressure(k)*qvs(k)*f5*2*(temp(k)-svp3)*tempd(k)&
&        /(pressure(k)-es(k)))/(temp(k)-svp3)**4)/(1.+pressure(k)/(&
&        pressure(k)-es(k))*qvs(k)*f5/(temp(k)-svp3)**2)**2
      qv2cl(k) = (qv(k)-qvs(k))/(1.+pressure(k)/(pressure(k)-es(k))*qvs(&
&        k)*f5/(temp(k)-svp3)**2)
! sub sat rain evaperate
      rn2qvd(k) = 0.0
      rn2qv(k) = 0.0
      ernd(k) = 0.0
      ern(k) = 0.0
      IF (qvs(k) .GT. qv(k)) THEN
        IF (qr(k) .GE. 1d-5) THEN
          rn2qvd(k) = dt*(((124.9*.2046*(rcgs(k)*qr(k))**(-0.7954)*(&
&            rcgsd(k)*qr(k)+rcgs(k)*qrd(k))*(rcgs(k)*qr(k))**.525+(1.6+&
&            124.9*(rcgs(k)*qr(k))**.2046)*.525*(rcgs(k)*qr(k))**(-0.475)&
&            *(rcgsd(k)*qr(k)+rcgs(k)*qrd(k)))*(2.55e8/(pressure(k)*qvs(k&
&            ))+5.4e5)+(1.6+124.9*(rcgs(k)*qr(k))**.2046)*(rcgs(k)*qr(k))&
&            **.525*2.55e8*(pressured(k)*qvs(k)+pressure(k)*qvsd(k))/(&
&            pressure(k)**2*qvs(k)**2))*(qvs(k)-qv(k))/((2.55e8/(pressure&
&            (k)*qvs(k))+5.4e5)**2*rcgs(k)*qvs(k))+(1.6+124.9*(rcgs(k)*qr&
&            (k))**.2046)*(rcgs(k)*qr(k))**.525*((qvsd(k)-qvd(k))*rcgs(k)&
&            *qvs(k)-(qvs(k)-qv(k))*(rcgsd(k)*qvs(k)+rcgs(k)*qvsd(k)))/((&
&            2.55e8/(pressure(k)*qvs(k))+5.4e5)*rcgs(k)**2*qvs(k)**2))
          rn2qv(k) = dt*((1.6+124.9*(rcgs(k)*qr(k))**.2046)*(rcgs(k)*qr(&
&            k))**.525/(2.55e8/(pressure(k)*qvs(k))+5.4e5))*((qvs(k)-qv(k&
&            ))/(rcgs(k)*qvs(k)))
        ELSE
          rn2qvd(k) = 0.0
          rn2qv(k) = 0.0
        END IF
        IF (rn2qv(k) .GT. qr(k)) THEN
          rn2qvd(k) = qrd(k)
          rn2qv(k) = qr(k)
        END IF
        ernmax = 0.0
        IF (-qv2cl(k) - qc(k) .GT. 0.0) THEN
          ernmaxd = -qv2cld(k) - qcd(k)
          ernmax = -qv2cl(k) - qc(k)
        ELSE
          ernmaxd = 0.0
        END IF
!        ern(k)  = amin1(rn2qv(k), ernmax)
        ernd(k) = rn2qvd(k)
        ern(k) = rn2qv(k)
        IF (rn2qv(k) .GT. ernmax) THEN
          ernd(k) = ernmaxd
          ern(k) = ernmax
        END IF
      END IF
! Update all variables
!       product = amax1(qv2cl(k),-qc(k))
      productd = qv2cld(k)
      product = qv2cl(k)
      IF (qv2cl(k) .LT. -qc(k)) THEN
        productd = -qcd(k)
        product = -qc(k)
      END IF
!       qv(k) = amax1(qv(k) - product + ern(k),0.)
      qvd(k) = qvd(k) - productd + ernd(k)
      qv(k) = qv(k) - product + ern(k)
      IF (qv(k) .LT. 0) THEN
        qvd(k) = 0.0
        qv(k) = 0.0
      END IF
      qcd(k) = qcd(k) + productd
      qc(k) = qc(k) + product
      qrd(k) = qrd(k) - ernd(k)
      qr(k) = qr(k) - ern(k)
      tempd(k) = tempd(k) + xlv*(productd-ernd(k))/cp
      temp(k) = temp(k) + xlv/cp*(product-ern(k))
      tmpd(k) = (tempd(k)*pii(k)-temp(k)*piid(k))/pii(k)**2
      tmp(k) = temp(k)/pii(k)
    END DO
  END SUBROUTINE SATADJ_D

END MODULE G_MODULE_MP_MKESSLER
