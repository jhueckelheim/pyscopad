! *id* stassuij ***********************************************************
! subroutine for
! |cl> = [1 + Uij + SUM(k.ne.ij) {X(ik),X(jk)} tau(i).tau(j)] |cr>
! with X(ij)=u3psv(rij)sigma(i).sigma(j)+u3ptv(rij)Sij
!      Uij is 2-body f6 operator

      subroutine stassuij ( k12, cl, cr, v3cuse )

      implicit real*8 (a-h,o-z)
      implicit integer (i-n)
!      include "parameters.fh"
      complex(8) :: cl(nsp,nt), cr(nsp,nt)
      real(8) :: v3cuse(numv3c)
!      include "params.fh"
!      include "ispin.fh"
!      include "lbp.fh"
!      include "pairs.fh"
!      include "pass.fh"
!      include "spin.fh"
!      include 'tbodyc.fh'
!      include "speed.fh"

      complex(8) :: ctt(nsp,nt), cf23, cf56, cuu, cdd, cs, cfe, cf1, cf2, cfd
      complex(8) h2pi_s(5), gind(5)
! ----------------------------------------------------------------------

      call stassterms (k12, .true., v3cuse, fn1, fn2, f1r, f1i, f2r, f2i, fdr, fdi, fer, fei,  
     &   h2pi_s, wex, gind, vcent)
!  for l3bc = -6, vcent is put in the w.f. elsewhere
      if ( l3bc == -6 ) vcent = 0 
!
      xt=utv(k12)
      xs=usv(k12)-utnv(k12)
      xst=ustv(k12)-utntv(k12)
      xtn=3*utnv(k12)
      xtnt=3*utntv(k12)
!   terms for uu -> uu, without & with tau.tau, and also dd -> dd
      xee = 1+xs+vcent + fr(1,k12)*xtn - wex
      xeet = xt+xst + fr(1,k12)*xtnt + fn1
!   terms for ud -> ud, without & with tau.tau, and also du -> du
      xmm = 1-xs+vcent - fr(1,k12)*xtn
      xmmt = xt-xst - fr(1,k12)*xtnt + fn2
!   terms for ud -> du, without & with tau.tau, and also du -> ud
      xmmp = 2*xs + fr(4,k12)*xtn - wex
      xmmpt = 2*xst + fr(4,k12)*xtnt
      cfe = dcmplx( fer, fei )
!   terms for  ud,du <--> dd,uu
      cf23 = dcmplx( fr(2,k12), fr(3,k12) )
      cf1 = dcmplx( f1r, f1i )
      cf2 = dcmplx( f2r, f2i )
!   terms for  uu <--> dd
      cf56 = dcmplx( fr(5,k12), fr(6,k12) )
      cfd = dcmplx( fdr, fdi )

      do  j=1,nt

! --------------
! ispin exchange
! --------------
        do i = 1, ns
            ctt(i,j) = 0.
        enddo
        do  jp=1,nt
            if (tdott(j,jp,k12).ne.0.) then
               tdt=tdott(j,jp,k12)
               do  i = 1, ns
                  ctt(i,j) = ctt(i,j)+tdt*cr(i,jp)
               enddo
            end if
        enddo
      enddo

      continue
!$OMP PARALLEL DO  SCHEDULE( DYNAMIC ) SHARED( tdott, cr, cl, ctt )   PRIVATE( i, j, jp, ig, idd, iud, idu, iuu, tdt, cuu, cdd, cs, sgn )
      do  j=1,nt

! --------------------------------------
! spin exchange and spin flip operations
! --------------------------------------

!  the anticommutator operator has the structure
!
!                  dd     ud     du     uu
!
!          dd      fn1    f1     f2     fd
!          ud      f1*    fn2    fe    -f2
!          du      f2*    fe*    fn2   -f1
!          uu      fd*   -f2*   -f1*    fn1
!
!    with fn real.

!    The spin structure of the U6 operator is

!            dd          ud           du         uu
!
!    dd    xs + f1      -f23         -f23        f56
!    ud     -f23*     -xs - f1     2xs + f4      f23
!    du     -f23*     2xs + f4     -xs - f1      f23
!    uu      f56*        f23*         f23*     xs + f1

!  where  f23=f2+if3;  f56=f5+if6;  f1 & f4 are real and
!  fi = fr(i)*xtn

        if ( .not. mss_flip(k12) ) then

           do  ig=1,nsg
              idd=mss(1,ig,k12)
              iud=mss(2,ig,k12)
              idu=mss(3,ig,k12)
              iuu=mss(4,ig,k12)

              cuu = xtn*cr(iuu,j) + xtnt*ctt(iuu,j)
              cdd = xtn*cr(idd,j) + xtnt*ctt(idd,j)
              cs = xtn*( cr(idu,j) + cr(iud,j) ) + xtnt*( ctt(idu,j) + ctt(iud,j) )

              cl(idd,j) = xee*cr(idd,j) + xeet*ctt(idd,j) + cf56*cuu - cf23*cs  
     &           + cf1*ctt(iud,j) + cf2*ctt(idu,j) + cfd*ctt(iuu,j)
              cl(iuu,j) = xee*cr(iuu,j) + xeet*ctt(iuu,j) + conjg(cf56)*cdd + conjg(cf23)*cs  
     &           - conjg(cf2)*ctt(iud,j) - conjg(cf1)*ctt(idu,j) + conjg(cfd)*ctt(idd,j)

              cl(iud,j) = xmm*cr(iud,j) + xmmt*ctt(iud,j) + xmmp*cr(idu,j)  
     &           + (xmmpt+cfe)*ctt(idu,j) + ( cf23*cuu - conjg(cf23)*cdd )  
     &           + conjg(cf1)*ctt(idd,j) - cf2*ctt(iuu,j)
              cl(idu,j) = xmm*cr(idu,j) + xmmt*ctt(idu,j) + xmmp*cr(iud,j) 
     &           + (xmmpt+conjg(cfe))*ctt(iud,j) + ( cf23*cuu - conjg(cf23)*cdd )  
     &           + conjg(cf2)*ctt(idd,j) - cf1*ctt(iuu,j)
 
           enddo

        else

           do  ig=1,nsg
              idd=mss(1,ig,k12)
              iud=mss(2,ig,k12)
              idu=mss(3,ig,k12)
              iuu=mss(4,ig,k12)
              sgn = mss_sign(ig,k12)

              cuu = -sgn*conjg( xtn*cr(iuu,j) + xtnt*ctt(iuu,j) )
              cdd = xtn*cr(idd,j) + xtnt*ctt(idd,j)
              cs = xtn*( sgn*conjg(cr(idu,j)) + cr(iud,j) ) + xtnt*( sgn*conjg(ctt(idu,j)) + ctt(iud,j) )

              cl(idd,j) = xee*cr(idd,j) + xeet*ctt(idd,j) + cf56*cuu - cf23*cs  
     &           + cf1*ctt(iud,j) + cf2*sgn*conjg(ctt(idu,j)) - cfd*sgn*conjg(ctt(iuu,j))
              cl(iuu,j) = xee*cr(iuu,j) + xeet*ctt(iuu,j) - sgn*conjg( conjg(cf56)*cdd + conjg(cf23)*cs )  
     &           - sgn*conjg( -conjg(cf2)*ctt(iud,j) + conjg(cfd)*ctt(idd,j) ) +cf1*ctt(idu,j)

              cl(iud,j) = xmm*cr(iud,j) + xmmt*ctt(iud,j)  
     &           + sgn*( xmmp*conjg(cr(idu,j)) + (xmmpt+cfe)*conjg(ctt(idu,j)) ) + ( cf23*cuu - conjg(cf23)*cdd )  
     &           + conjg(cf1)*ctt(idd,j) + cf2*sgn*conjg(ctt(iuu,j))
              cl(idu,j) = xmm*cr(idu,j) + xmmt*ctt(idu,j)  
     &           + sgn*( xmmp*conjg(cr(iud,j)) + (xmmpt+cfe)*conjg(ctt(iud,j)) + conjg( cf23*cuu - conjg(cf23)*cdd ) )  
     &           + sgn*conjg( conjg(cf2)*ctt(idd,j) ) + conjg(cf1)*ctt(iuu,j) 

           enddo

        endif

      enddo

      flops=flops+((13+10+26+2*(30)+2)*(npart-2)  
     &   +4*ns*ntdott(k12)+(4+(12+10+40+42 +4*12+4*10)*nsg*nt))
      return
      end
